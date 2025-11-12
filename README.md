[blueprint](https://github.com/user-attachments/files/23503675/blueprint_cropped.pdf)
```mermaid
flowchart TB
%% ========= Huda v2 Code Blueprint (fixed) =========

%% External
firestore[(Firebase Firestore)]

%% -------- example/data --------
subgraph exData["example/data"]
  direction TB

  subgraph exModels["models"]
    page_model[page_model.dart]
    lesson_model[lesson_model.dart]
    unit_model[unit_model.dart]
    level_model[level_model.dart]
  end

  subgraph exProviders["providers (ChangeNotifier)"]
    units_provider[units_provider.dart]
    lesson_provider[lesson_provider.dart]
  end

  subgraph exServices["services"]
    lessons_service[lessons_service.dart]
  end
end

%% -------- lib/models & lib/mock --------
subgraph libModels["lib/models & lib/mock"]
  section_model[section_model.dart]
  mock_sections[mock_sections.dart]
end

%% -------- lib/providers --------
subgraph libProviders["lib/providers"]
  sections_provider[sections_provider.dart]
  navigation_provider[navigation_provider.dart]
  user_stats_provider[user_stats_provider.dart]
end

%% -------- example/lib --------
subgraph exLib["example/lib"]
  direction TB

  subgraph controllers["controllers"]
    page_transition_controller[page_transition_controller.dart]
  end

  subgraph pagesCore["pages (core screens)"]
    intro_page[intro_page.dart]
    video_call_page[video_call_page.dart]
    steps_page[steps_page.dart]
  end

  subgraph presPages["presentation/pages"]
    units_page[units_page.dart]
    lesson_page[lesson_page.dart]
  end

  subgraph presWidgets["presentation/widgets"]
    exercise_intro_widget[exercise_intro_widget.dart]
    crud_menu[crud_menu.dart]
    exercise_widget_factory[exercise_widget_factory.dart]
    hover_label[hover_label.dart]
    level_icons_svg[level_icons_svg.dart]
    level_icons[level_icons.dart]
    level_tile[level_tile.dart]
    unit_header[unit_header.dart]
    unit_sections[unit_sections.dart]
  end

  subgraph coreWidgets["widgets (shared)"]
    adaptive_app_bar[adaptive_app_bar.dart]
    adaptive_bottom_nav[adaptive_bottom_nav.dart]
    section_card[section_card.dart]
    unit_icon[unit_icon.dart]
  end

  theme[theme/...]
  main_file[main.dart]
end

%% ========= Relationships =========

%% Services -> Firestore
lessons_service --> firestore

%% Providers -> Services
units_provider --> lessons_service
lesson_provider --> lessons_service

%% Pages use Providers
units_page --> units_provider
lesson_page --> lesson_provider
intro_page --> sections_provider
video_call_page --> navigation_provider
steps_page --> user_stats_provider

%% Pages use Controller
intro_page --> page_transition_controller
video_call_page --> page_transition_controller
steps_page --> page_transition_controller
units_page --> page_transition_controller
lesson_page --> page_transition_controller

%% Widgets consumed by Pages (sample links)
exercise_widget_factory --> lesson_page
exercise_intro_widget --> lesson_page
level_tile --> units_page
unit_header --> units_page
unit_sections --> units_page
section_card --> intro_page
adaptive_app_bar --> intro_page
adaptive_bottom_nav --> intro_page
unit_icon --> intro_page

%% Models feed Providers/Services/UI
page_model --> units_provider
lesson_model --> lesson_provider
unit_model --> lessons_service
level_model --> lessons_service
section_model --> units_page
mock_sections --> units_page

%% App bootstrap
main_file --> theme
main_file --> intro_page
main_file --> units_page
main_file --> lesson_page
