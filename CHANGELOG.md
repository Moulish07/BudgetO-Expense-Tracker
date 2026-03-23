[2.1.0+3] - 2026-03-23

🎨 UI & UX Overhaul

Multi-Theme Engine: Integrated a dynamic theme system with three distinct modes:

Glass Blue: Full glassmorphism with real-time blur.

Dark Purple: High-contrast OLED dark mode.

Ivory Light: Clean, light-mode aesthetic for high readability.

Glassmorphic Feedback: Replaced standard SnackBars with custom frosted, blurred floating alerts for success and deletion actions.

Refined Dashboard: Standardized the "Current Balance" card into a premium fixed-width header with internal gradients.

Safe-Zone Visuals: Adjusted Chart and List components to prevent clipping and overlap with the navigation bar.

🛠 Functional Updates

2005 Bengal Mode: Added a historical inflation multiplier (0.45x) toggle in the sidebar to visualize current spending in 2005 currency values—specifically designed for historical novel research.

Advanced History Search: Added a dedicated search dialog to filter previous transactions by keywords or categories across the entire archive.

Safe Deletion: Implemented a blurred confirmation dialog before deleting records to prevent accidental data loss.

🔧 Fixes & Stability

Background Picker: Fixed a critical bug in the wallpaper selection logic regarding XFile to File conversion.

Theme Persistence: Theme selection is now globally managed via ChangeNotifier and persists locally using Hive.

Cloud Sync Integrity: Improved syncAllToCloud logic to better manage session-based data pushes.