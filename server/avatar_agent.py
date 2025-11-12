from dotenv import load_dotenv
from livekit import agents, rtc
from livekit.agents import AgentSession, stt as livekitstt, llm as livekitllm, tts as livekittts
from livekit.agents import UserInputTranscribedEvent
from livekit.agents import SpeechCreatedEvent
from livekit.plugins import openai, tavus, elevenlabs, silero, anthropic
from livekit import api
import os
import logging
import asyncio
import json
import subprocess
import psutil
import atexit

from openai.types.beta.realtime.session import InputAudioTranscription, TurnDetection
from AgentInstructions import DebugAvatarAgent
import sys, signal, time, threading, shutil
from dataclasses import dataclass

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
ELEVEN_API_KEY = os.getenv("ELEVEN_API_KEY")
TAVUS_API_KEY = os.getenv("TAVUS_API_KEY")
replica_id = os.getenv("TAVUS_REPLICA_ID")
persona_id = os.getenv("TAVUS_PERSONA_ID")
voice_id = os.getenv("ELEVEN_VOICE_ID")
model = os.getenv("ELEVEN_MODEL")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
LIVEKIT_URL = os.getenv("LIVEKIT_URL")
LIVEKIT_API_KEY = os.getenv("LIVEKIT_API_KEY")
LIVEKIT_API_SECRET = os.getenv("LIVEKIT_API_SECRET")
EXPECTED_USER_IDENTITY = os.getenv("EXPECTED_USER_IDENTITY")
AVATAR_LANGUAGE = os.getenv("AVATAR_LANGUAGE") 
AVATAR_LANGUAGE_STT = os.getenv("AVATAR_LANGUAGE_STT")

# ---------------------------------------------------------------------------
# Fallback process registry utilities (unchanged)
# ---------------------------------------------------------------------------
@dataclass
class FallbackProc:
    room: str
    popen: subprocess.Popen
    popup: bool
    started_ts: float

logger = logging.getLogger(__name__)

def force_kill_self(room_name: str | None = None, kill_fallback_only: bool = False, kill_self: bool = False):
    """Kill all avatar agent processes for this room"""
    if room_name:
        try:
            # Get all processes
            result = subprocess.run(
                ["ps", "-eo", "pid,cmd"],
                capture_output=True,
                text=True,
                check=True
            )
            
            pids_to_kill = []
            if kill_fallback_only:
                target_files = ['avatar_agent_fallback.py']
            else:
                target_files = ['avatar_agent.py', 'avatar_agent_fallback.py']

            for line in result.stdout.strip().split('\n'):
                if room_name in line and any(f in line for f in target_files):
                    # Extract PID (first field)
                    pid = line.split()[0]
                    try:
                        pid_int = int(pid)
                        # Don't add our own PID
                        if pid_int != os.getpid():
                            pids_to_kill.append(pid_int)
                    except ValueError:
                        continue
            
            # Kill all found PIDs
            for pid in pids_to_kill:
                try:
                    logger.info(f"Killing agent process PID {pid} for room {room_name}")
                    os.kill(pid, signal.SIGKILL)
                except ProcessLookupError:
                    logger.info(f"Process {pid} already dead")
                except Exception as e:
                    logger.error(f"Failed to kill PID {pid}: {e}")
                    
            logger.info(f"Killed {len(pids_to_kill)} agent processes for room {room_name}")
            if kill_self:
                os.kill(os.getpid(), signal.SIGKILL)
            
        except Exception as e:
            logger.error(f"Error in force_kill_self: {e}")
    else: pass


# ---------------------------------------------------------------------------
# Global logging config (root + libs) --------------------------------------
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logging.getLogger("livekit").setLevel(logging.DEBUG)
logging.getLogger("tavus").setLevel(logging.DEBUG)

# Signal handler to ensure process dies
def signal_handler(signum, frame):
    logger.error(f"Received signal {signum} - FORCE KILLING")
    os.kill(os.getpid(), signal.SIGKILL)

# Register signal handlers
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

# Register atexit handler as final failsafe
def atexit_handler():
    logger.error("ATEXIT: Process still running at exit - FORCE KILLING")
    os.kill(os.getpid(), signal.SIGKILL)

atexit.register(atexit_handler)


async def shutdown_now(ctx, session, avatar):
    logger.info("EMERGENCY SHUTDOWN INITIATED")
    force_kill_self(ctx.room.name)
    # Set a hard deadline - kill process in 10 seconds no matter what
    def deadline_kill():
        time.sleep(10)
        logger.error("DEADLINE: Shutdown taking too long, FORCE KILLING NOW!")
        if ctx.room.name:
            force_kill_self(ctx.room.name, kill_self=True)

    deadline_thread = threading.Thread(target=deadline_kill, daemon=True)
    deadline_thread.start()
    
    # Try quick cleanup (with very short timeouts)
    try:
        if session:
            logger.info("Closing session...")
            await asyncio.wait_for(
                session.close() if hasattr(session, 'close') else asyncio.sleep(0),
                timeout=1.0
            )
    except:
        pass
    
    try:
        if avatar:
            logger.info("Closing avatar...")
            if hasattr(avatar, 'close'):
                await asyncio.wait_for(avatar.close(), timeout=1.0)
            elif hasattr(avatar, 'disconnect'):
                await asyncio.wait_for(avatar.disconnect(), timeout=1.0)
    except:
        pass
    
    try:
        if ctx.room and ctx.room.is_connected:
            logger.info("Disconnecting room...")
            await asyncio.wait_for(ctx.room.disconnect(), timeout=1.0)
    except:
        pass
    
    # Don't wait, just kill immediately
    logger.info("Cleanup attempted, FORCE KILLING NOW")
    if ctx.room.name:
        force_kill_self(ctx.room.name, kill_self=True)
# ---------------------------------------------------------------------------
# fallback agent launcher (unchanged apart from minor formatting) ----------
# ---------------------------------------------------------------------------
async def start_new_agent_fallback(room_name: str):
    """Start a new Avatar agent for a specific room in a new terminal window"""
    logger.info("="*60)
    logger.info("STARTING FALLBACK AGENT LAUNCH")
    logger.info("="*60)
    
    force_kill_self(room_name, kill_fallback_only=True)
    
    # Debug: Check if fallback script exists
    agent_script = os.path.join(os.path.dirname(__file__), "avatar_agent_fallback.py")
    if not os.path.exists(agent_script):
        logger.error(f"FALLBACK SCRIPT NOT FOUND: {agent_script}")
        return
    logger.info(f"Fallback script path: {agent_script}")
    
    # Debug: Check Python executable
    python_exe = sys.executable
    logger.info(f"Python executable: {python_exe}")
    
    # Copy environment
    env = os.environ.copy()
    env['EXPECTED_USER_IDENTITY'] = EXPECTED_USER_IDENTITY or ''
    env['AVATAR_LANGUAGE'] = AVATAR_LANGUAGE or ''
    env['AVATAR_LANGUAGE_STT'] = AVATAR_LANGUAGE_STT or ''
    
    # Debug: Log environment
    logger.info("Environment variables set for fallback:")
    logger.info(f"  EXPECTED_USER_IDENTITY: {env.get('EXPECTED_USER_IDENTITY', 'NOT SET')}")
    logger.info(f"  LIVEKIT_URL: {env.get('LIVEKIT_URL', 'NOT SET')}")
    logger.info(f"  TAVUS_API_KEY: {'SET' if env.get('TAVUS_API_KEY') else 'NOT SET'}")
    
    if sys.platform.startswith("win"):
        logger.info("Platform: Windows")
        try:
            creationflags = subprocess.CREATE_NEW_CONSOLE
            proc = subprocess.Popen(
                [python_exe, "-u", agent_script, "connect", "--room", room_name],
                creationflags=creationflags, 
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            logger.info(f"Started fallback agent for room {room_name} (Windows console). PID: {proc.pid}")
            
            # Check if process is still running after 1 second
            await asyncio.sleep(1)
            if proc.poll() is not None:
                stdout, stderr = proc.communicate()
                logger.error(f"Fallback process died immediately! Exit code: {proc.returncode}")
                logger.error(f"STDOUT: {stdout.decode('utf-8', errors='ignore')}")
                logger.error(f"STDERR: {stderr.decode('utf-8', errors='ignore')}")
            else:
                logger.info(f"Fallback process still running after 1 second")
            return
        except Exception as e:
            logger.error(f"Failed to start Windows fallback: {e}", exc_info=True)
            return
    
    # Linux/Mac handling
    logger.info("Platform: Linux/Mac")
    SHOW_FB_TERMINAL = False
    log_path = os.path.join(os.path.dirname(__file__), "fallback.log")
    
    # Always try to write to log file first
    try:
        with open(log_path, "a") as f:
            f.write(f"\n{'='*60}\n")
            f.write(f"Fallback agent starting at {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Room: {room_name}\n")
            f.write(f"{'='*60}\n")
    except Exception as e:
        logger.error(f"Cannot write to fallback log: {e}")
    
    popup = False
    
    if SHOW_FB_TERMINAL:
        term = os.getenv("TERMINAL")
        if not term:
            logger.info("No TERMINAL env var, searching for terminal emulator...")
            for c in ["gnome-terminal", "x-terminal-emulator", "xterm", "konsole", "terminator", "alacritty"]:
                if shutil.which(c):
                    term = c
                    logger.info(f"Found terminal: {c}")
                    break
        
        if term:
            logger.info(f"Using terminal: {term}")
            if term in ("gnome-terminal", "konsole"):
                full_cmd = [term, "--", python_exe, "-u", agent_script, "connect", "--room", room_name]
            elif term == "alacritty":
                full_cmd = [term, "-e", python_exe, "-u", agent_script, "connect", "--room", room_name]
            else:
                full_cmd = [term, "-e", python_exe, "-u", agent_script, "connect", "--room", room_name]
            popup = True
            preexec = None
        else:
            logger.warning("No terminal emulator found, running headless")
            full_cmd = [python_exe, "-u", agent_script, "connect", "--room", room_name]
            preexec = os.setsid
    else:
        logger.info("SHOW_FB_TERMINAL=False, running headless")
        full_cmd = [python_exe, "-u", agent_script, "connect", "--room", room_name]
        preexec = os.setsid
    
    logger.info(f"Full command: {' '.join(full_cmd)}")
    
    try:
        # Open log file for subprocess output
        log_file = open(log_path, "a", encoding="utf-8")
        
        # Start the process
        proc = subprocess.Popen(
            full_cmd, 
            stdout=log_file if not popup else subprocess.PIPE, 
            stderr=subprocess.STDOUT if not popup else subprocess.PIPE,
            preexec_fn=preexec, 
            env=env
        )
        
        log_file.close()
        logger.info(f"Started fallback agent for room {room_name}. PID: {proc.pid}")
        logger.info(f"Output -> {log_path}")
        
        # Check if process is still running after 2 seconds
        await asyncio.sleep(2)
        if proc.poll() is not None:
            logger.error(f"Fallback process died immediately! Exit code: {proc.returncode}")
            if popup:
                stdout, stderr = proc.communicate()
                logger.error(f"STDOUT: {stdout.decode('utf-8', errors='ignore')}")
                logger.error(f"STDERR: {stderr.decode('utf-8', errors='ignore')}")
            else:
                # Read last lines from log file
                try:
                    with open(log_path, "r") as f:
                        lines = f.readlines()
                        logger.error("Last 20 lines from fallback.log:")
                        for line in lines[-20:]:
                            logger.error(f"  {line.rstrip()}")
                except Exception as e:
                    logger.error(f"Could not read fallback.log: {e}")
        else:
            logger.info(f"Fallback process still running after 2 seconds")
            
            # Try to verify it's actually working
            if not popup:
                try:
                    process = psutil.Process(proc.pid)
                    logger.info(f"Process status: {process.status()}")
                    logger.info(f"Process CPU: {process.cpu_percent()}%")
                except Exception as e:
                    logger.error(f"Could not check process status: {e}")
                    
    except Exception as e:
        logger.error(f"Failed to start Linux/Mac fallback: {e}", exc_info=True)
        


# ---------------------------------------------------------------------------
# entrypoint ----------------------------------------------------------------
# ---------------------------------------------------------------------------
async def entrypoint(ctx: agents.JobContext):
    """Main entry point with proper cleanup and error handling"""

    logger.info("="*60)
    logger.info(f"Room name: {ctx.room.name}")
    avatar = None
    session = None
    fallback_triggered = False

    async def trigger_fallback(error_msg: str):
        nonlocal fallback_triggered
        if fallback_triggered:
            return
        fallback_triggered = True
        logger.error(f"❌ Custom STS stack failing, LAUNCHING FALLBACK AGENT... the error btw: {error_msg}")
        try:
            await ctx.room.disconnect()
            await start_new_agent_fallback(ctx.room.name)
            return
        except Exception as fallback_error:
            logger.error(f"❌ Runtime fallback failed: {fallback_error}")

    try:
        # ------------------------------------------------------------------
        # Connect to room
        # ------------------------------------------------------------------
        # Try to disable automatic close on disconnect
        if hasattr(ctx, 'room_input_options'):
            ctx.room_input_options = agents.RoomInputOptions(close_on_disconnect=False)
        await ctx.connect(auto_subscribe=agents.AutoSubscribe.AUDIO_ONLY)

        # ------------------------------------------------------------------
        # Create Tavus avatar
        # ------------------------------------------------------------------
        avatar = tavus.AvatarSession(replica_id=replica_id, persona_id=persona_id)

        # ------------------------------------------------------------------
        # Create custom STS stack
        # ------------------------------------------------------------------
        session = None
        greeting_message = ""
        agent_system_type = "unknown"
        try:
            vad = silero.VAD.load()
            if AVATAR_LANGUAGE_STT == "detect":
                stt = livekitstt.FallbackAdapter([openai.STT(model="gpt-4o-transcribe", detect_language=True), openai.STT(model="whisper-1", detect_language=True)], vad=vad)
            else:
                stt = livekitstt.FallbackAdapter([openai.STT(model="gpt-4o-transcribe",language=AVATAR_LANGUAGE_STT), openai.STT(model="whisper-1", language=AVATAR_LANGUAGE_STT)], vad=vad)
            
            llm = livekitllm.FallbackAdapter([openai.LLM(model="gpt-4o", temperature=0.7), anthropic.LLM(model="claude-sonnet-4-20250514", temperature=0.7)])

            tts = livekittts.FallbackAdapter([elevenlabs.TTS(voice_id=voice_id, model=model, api_key=ELEVEN_API_KEY), openai.TTS(model="gpt-4o-mini-tts", voice="ash"), openai.TTS(model="tts-1", voice="ash")])

            session = AgentSession(stt=stt, llm=llm, tts=tts, vad=vad)

            agent_system_type = "elevenlabs"
        except Exception as sts_error:
            logger.info(f"🚨 CRITICAL: Custom STS stack failed to initialize! LAUNCHING FALLBACK AGENT... the error btw: {sts_error}")
            try:
                await ctx.room.disconnect()
                await start_new_agent_fallback(ctx.room.name)
                logger.info("✅ FALLBACK AGENT LAUNCHED SUCCESSFULLY!")
                if True:
                    # ------------------------------------------------------------------
                    # Monitor participants and exit when *human* participants leave
                    # ------------------------------------------------------------------
                    expected_user = EXPECTED_USER_IDENTITY
                    logger.info(f"Expected user identity: {expected_user}")
                    user_left = asyncio.Event()
                    

                    # Here's where we catch the disconnection of the expected user
                    def _on_p_disconnected(p): 
                        if expected_user and p.identity == expected_user:
                            user_left.set()
                    ctx.room.on("participant_disconnected", _on_p_disconnected) # And here its called
                    
                    if expected_user:
                        try:
                            await user_left.wait()
                            logger.info("User %s left; 4s grace then shutdown.", expected_user)
                            await asyncio.sleep(4)
                            await shutdown_now(ctx, session, avatar)
                            force_kill_self(ctx.room.name, kill_self=True)
                        except asyncio.CancelledError:
                            logger.warning("Shutdown cancelled by framework - forcing termination anyway!")
                            await shutdown_now(ctx, session, avatar)
                            force_kill_self(ctx.room.name, kill_self=True)
                        return
                    else:
                        logger.info("No expected user identity set; Failing to continue")

            except Exception as fallback_error:
                logger.error(f"💀 Complete failure - check configuration and restart manually. error: {fallback_error}")
                await asyncio.sleep(5)
                await shutdown_now(ctx, session, avatar)
                force_kill_self(ctx.room.name, kill_self=True)

        if session is None:
            raise RuntimeError("Failed to create any session (both primary and fallback failed)")

        # ------------------------------------------------------------------
        # Start avatar in room
        # ------------------------------------------------------------------

        # This publishes the avatar video to the room
        await avatar.start(session, room=ctx.room)


        # ------------------------------------------------------------------
        # Start interactive session
        # ------------------------------------------------------------------
        agent = DebugAvatarAgent(system_type="elevenlabs")
        greeting_message = agent.get_greeting_message()
        # Disable automatic close on participant disconnect
        session._room_input_options = agents.RoomInputOptions(close_on_disconnect=False)
        await session.start(room=ctx.room, agent=agent)

        # --- Temp instruction state (one-turn override) ---
        agent._orig_instructions = agent._current_instructions  # Use the internal variable
        agent._temp_prompt_active = False
        agent._temp_prompt_purpose = None
        agent._temp_prompt_text = None

        # --- For voice-initiated turns (not user_message), use speech_created to know when to restore ---
        @session.on("speech_created")
        def _on_speech_created(ev: SpeechCreatedEvent):
            # We already emit started/ended around generate_reply() for text messages we initiate.
            # For VOICE turns (auto replies), user_initiated == False -> we emit here.
            if getattr(ev, "user_initiated", False):
                return
            async def _emit_started():
                try:
                    started = json.dumps({"type": "avatar_speech_started"})
                    await ctx.room.local_participant.publish_data(
                        started.encode("utf-8"), reliable=True, topic="avatar"
                    )
                except Exception as e:
                    logger.warning(f"Could not emit avatar_speech_started (voice): {e}")
            asyncio.create_task(_emit_started())

            # When speech finishes, emit ended and, if a temp prompt was active, restore defaults.
            def _on_done(_):
                async def _finish_and_restore():
                    try:
                        ended = json.dumps({"type": "avatar_speech_ended"})
                        await ctx.room.local_participant.publish_data(
                            ended.encode("utf-8"), reliable=True, topic="avatar"
                        )
                    finally:
                        if getattr(agent, "_temp_prompt_active", False):
                            await agent.update_instructions(agent._orig_instructions)  # <-- revert remotely
                            agent._current_instructions = agent._orig_instructions     # <-- sync local property
                            agent._temp_prompt_active = False
                            purpose = agent._temp_prompt_purpose
                            agent._temp_prompt_purpose = None
                            agent._temp_prompt_text = None
                            logger.info(f"System prompt reset to default after one voice turn (was '{purpose}')")
                asyncio.create_task(_finish_and_restore())

            # Attach completion callback to the speech handle
            try:
                ev.speech_handle.add_done_callback(_on_done)
            except Exception as e:
                logger.warning(f"Could not attach done callback to speech handle: {e}")

        # --- Listen for data messages ---
        def on_data_received(data_packet: rtc.DataPacket):
            async def handle_data():
                try:
                    message = data_packet.data.decode('utf-8')
                    logger.debug(f"📥 Received raw data message: {message[:200] if len(message) > 200 else message}")
                    
                    data_obj = json.loads(message)
                    
                    if data_obj.get('type') == 'user_message':
                        content = data_obj.get('content', '')
                        
                        # Enhanced content validation and logging
                        if not content or not content.strip():
                            logger.warning("❌ Received empty content in user_message - skipping processing")
                            return
                        
                        content = content.strip()
                        logger.info(f"📤 Processing user message: '{content[:100]}{'...' if len(content) > 100 else ''}' ({len(content)} chars)")
                        
                        try:
                            # Emit speech started event
                            logger.debug("🗣️ Emitting avatar_speech_started event")
                            speech_started_msg = json.dumps({"type": "avatar_speech_started"})
                            await ctx.room.local_participant.publish_data(
                                speech_started_msg.encode('utf-8'), reliable=True, topic="avatar"
                            )
                            logger.debug("✅ avatar_speech_started event emitted successfully")
                            
                            # Generate the reply (includes TTS streaming)
                            logger.debug(f"🤖 Starting reply generation for content: '{content[:50]}...'")
                            handle = await session.generate_reply(user_input=content)
                            logger.debug("✅ Reply generation initiated")
                            
                            # Wait for the TTS audio to finish playing to LiveKit
                            logger.debug("⏳ Waiting for TTS playout to complete...")
                            await handle.wait_for_playout()
                            logger.debug("✅ TTS playout completed successfully")
                            
                            # Authoritatively signal EOS to clients
                            logger.debug("🔚 Emitting avatar_speech_ended event")
                            speech_ended_msg = json.dumps({"type": "avatar_speech_ended"})
                            await ctx.room.local_participant.publish_data(
                                speech_ended_msg.encode('utf-8'), reliable=True, topic="avatar"
                            )
                            logger.debug("✅ avatar_speech_ended event emitted successfully")

                            # If a temporary system prompt was in effect for a text turn, clear it now
                            if getattr(agent, "_temp_prompt_active", False):
                                await agent.update_instructions(agent._orig_instructions)  # <-- revert remotely
                                agent._current_instructions = agent._orig_instructions     # <-- sync local property
                                agent._temp_prompt_active = False
                                purpose = agent._temp_prompt_purpose
                                agent._temp_prompt_purpose = None
                                agent._temp_prompt_text = None
                                logger.info(f"System prompt reset to default after one text turn (was '{purpose}')")
                            
                        except Exception as e:
                            logger.error(f"❌ Error processing prompt: {e}", exc_info=True)
                            # Even if there's an error, signal that speech ended
                            try:
                                logger.debug("⚠️ Error occurred - sending emergency avatar_speech_ended event")
                                error_msg = json.dumps({
                                    "type": "avatar_speech_ended",
                                    "error": True,
                                    "message": str(e)
                                })
                                await ctx.room.local_participant.publish_data(
                                    error_msg.encode('utf-8'), reliable=True, topic="avatar"
                                )
                                logger.debug("✅ Emergency avatar_speech_ended event sent")
                            except Exception as cleanup_error:
                                logger.error(f"❌ Failed to send emergency speech_ended event: {cleanup_error}")
                    elif data_obj.get('type') == 'system_prompt':
                        purpose = (data_obj.get('purpose') or "").strip().lower()
                        prompt = (data_obj.get('content') or "").strip()
                        logger.debug(f"📋 Received system_prompt with purpose='{purpose}' and content length={len(prompt)} chars")
                        if purpose in ["pronunciation", "debug_override"] and prompt:
                            # prevent overlapping temp prompts
                            if getattr(agent, "_temp_prompt_active", False):
                                logger.warning("Temp system prompt already active; ignoring new one until current completes.")
                                return
                            
                            try:
                                # store original and apply a one-turn override
                                agent._orig_instructions = agent.instructions
                                await agent.update_instructions(prompt)      # <-- propagate to running session
                                agent._current_instructions = prompt         # <-- keep your override property in sync
                                agent._temp_prompt_active = True
                                agent._temp_prompt_purpose = purpose
                                agent._temp_prompt_text = prompt
                                logger.info(f"Applied temporary '{purpose}' system prompt for next turn")
                                
                                # only ACK after the update was sent
                                try:
                                    ack = json.dumps({"type": "system_prompt_ack", "purpose": purpose})
                                    await ctx.room.local_participant.publish_data(
                                        ack.encode("utf-8"), reliable=True, topic="avatar"
                                    )
                                except Exception as e:
                                    logger.debug(f"Failed sending system_prompt_ack: {e}")
                                return
                                
                            except Exception as e:
                                logger.error(f"Failed to apply system prompt: {e}", exc_info=True)
                                return
                        else:
                            logger.debug(f"Ignoring system_prompt with purpose='{purpose}' or empty content.")
                            return
                    else:
                        logger.debug(f"📋 Received non-user-message data: type={data_obj.get('type', 'unknown')}")
                        
                except json.JSONDecodeError as e:
                    logger.error(f"❌ Error parsing data message as JSON: {e}")
                    logger.error(f"Raw data: {data_packet.data}")
                except Exception as e:
                    logger.error(f"❌ Error processing data message: {e}", exc_info=True)
            
            asyncio.create_task(handle_data())
        
        ctx.room.on("data_received", on_data_received)

        # ------------------------------------------------------------------
        # Initial greeting
        # ------------------------------------------------------------------
        try:
            await asyncio.sleep(1.5)
            # Emit speech started event for greeting
            greeting_started_msg = json.dumps({"type": "avatar_speech_started"})
            await ctx.room.local_participant.publish_data(
                greeting_started_msg.encode('utf-8'), reliable=True, topic="avatar"
            )
            logger.debug("Emitted avatar_speech_started event for greeting")
            
            # Generate greeting
            handle = await session.generate_reply(instructions=greeting_message)
            
            # Wait for greeting TTS to finish
            await handle.wait_for_playout()
            logger.debug("Greeting TTS playout completed")
            
            # Signal greeting speech ended
            greeting_ended_msg = json.dumps({"type": "avatar_speech_ended"})
            await ctx.room.local_participant.publish_data(
                greeting_ended_msg.encode('utf-8'), reliable=True, topic="avatar"
            )
            logger.debug("Emitted avatar_speech_ended event for greeting")
            
        except Exception as greeting_error:
            logger.warning(f"Could not send initial greeting: {greeting_error}")
            error_str = str(greeting_error).lower()
            if "invalid_api_key" in error_str or "api_key" in error_str:
                logger.error("API key error during greeting - triggering fallback")
                await trigger_fallback("API key error during initial greeting")
            else:
                logger.info("  - Will continue without initial greeting")


        # ------------------------------------------------------------------
        # Monitor participants and exit when *human* participants leave
        # ------------------------------------------------------------------
        expected_user = EXPECTED_USER_IDENTITY
        logger.info(f"Expected user identity: {expected_user}")
        user_left = asyncio.Event()

        def _on_p_disconnected(p):
            if expected_user and p.identity == expected_user:
                user_left.set()
        ctx.room.on("participant_disconnected", _on_p_disconnected)


        if expected_user:
            logger.info("Waiting for user %s to leave...", expected_user)
            try:
                await user_left.wait()
                logger.info("User %s left; 4s grace then shutdown.", expected_user)
                await asyncio.sleep(4)
                await shutdown_now(ctx, session, avatar)
                force_kill_self(ctx.room.name, kill_self=True)
            except asyncio.CancelledError:
                logger.warning("Shutdown cancelled by framework - forcing termination anyway!")
                await shutdown_now(ctx, session, avatar)
                force_kill_self(ctx.room.name, kill_self=True)
            return
        else:
            logger.info("No expected user identity set; Failing to continue.")

    except Exception as e:
        logger.error(f"ERROR in agent: {type(e).__name__}: {e}")

    finally:
        # Start a timer that will kill us in 5 seconds no matter what
        def final_kill():
            time.sleep(5)
            logger.error("FINALLY BLOCK TIMEOUT - FORCE KILLING!")
            force_kill_self(ctx.room.name)
        
        kill_timer = threading.Thread(target=final_kill, daemon=True)
        kill_timer.start()
        
        try:
            # Quick cleanup attempts
            if 'session' in locals() and session:
                logger.info("Finally: Stopping agent session...")
                try:
                    if hasattr(session, 'close'):
                        await asyncio.wait_for(session.close(), timeout=1)
                except:
                    pass
            if 'avatar' in locals() and avatar:
                logger.info("Finally: Stopping avatar...")
                try:
                    if hasattr(avatar, 'close'):
                        await asyncio.wait_for(avatar.close(), timeout=1)
                    elif hasattr(avatar, 'disconnect'):
                        await asyncio.wait_for(avatar.disconnect(), timeout=1)
                except:
                    pass
            if 'fallback_triggered' in locals() and fallback_triggered:
                force_kill_self(ctx.room.name, kill_fallback_only=True)
            if ctx.room and hasattr(ctx.room, 'is_connected') and ctx.room.is_connected:
                logger.info("Finally: Disconnecting from room...")
                try:
                    await asyncio.wait_for(ctx.room.disconnect(), timeout=1)
                except:
                    pass
        except:
            pass
        # Don't wait, just die
        force_kill_self(ctx.room.name)


if __name__ == "__main__":
    logger.info("Starting Tavus Avatar Agent Worker...")
    
    # Start a failsafe timer that will kill the process after 60 seconds no matter what
    def failsafe_kill():
        time.sleep(900)
        logger.error("FAILSAFE: Process still alive after 15 minutes, force killing!")
        os.killpg(os.getpgid(os.getpid()), signal.SIGKILL)
        os._exit(1)
    
    failsafe_thread = threading.Thread(target=failsafe_kill, daemon=True)
    failsafe_thread.start()
    
    agents.cli.run_app(
        agents.WorkerOptions(
            entrypoint_fnc=entrypoint,
        )
    )
