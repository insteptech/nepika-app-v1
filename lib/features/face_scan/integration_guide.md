# Face Scan Results Guided Tour - Integration Guide

## Quick Integration Steps

### 1. Import Required Files
Add these imports to your existing face scan result screen:

```dart
import '../../../core/mixins/guided_tour_mixin.dart';
import '../../../core/widgets/guided_tour_overlay.dart';
```

### 2. Add Mixin to Your Screen
Update your screen class to use the mixin:

```dart
class YourFaceScanResultScreen extends StatefulWidget {
  // Your existing code...
}

class _YourFaceScanResultScreenState extends State<YourFaceScanResultScreen> 
    with GuidedTourMixin {  // Add this mixin
  
  // Add global keys for tour targets
  final GlobalKey _conditionFilterKey = GlobalKey();
  final GlobalKey _resultButtonKey = GlobalKey();
  final GlobalKey _skinScoreKey = GlobalKey();
  final GlobalKey _recommendationsKey = GlobalKey();
  
  // Your existing code...
}
```

### 3. Add Keys to Your Widgets
Add the global keys to the widgets you want to highlight:

```dart
// Example: Add key to your condition filter
Container(
  key: _conditionFilterKey,  // Add this
  child: YourConditionFilterWidget(),
)

// Example: Add key to your result button
ElevatedButton(
  key: _resultButtonKey,  // Add this
  onPressed: () {}, 
  child: Text('View Results'),
)
```

### 4. Initialize Tour in initState
Add the tour initialization:

```dart
@override
void initState() {
  super.initState();
  // Your existing code...
  
  // Start tour after screen is built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _startFaceScanTour();
  });
}

Future<void> _startFaceScanTour() async {
  final tourSteps = [
    createTourStep(
      title: 'Condition Filters',
      description: 'Tap on different conditions to filter analysis results.',
      targetKey: _conditionFilterKey,
    ),
    createTourStep(
      title: 'Detailed Results',
      description: 'View your complete skin analysis report here.',
      targetKey: _resultButtonKey,
    ),
    // Add more steps as needed...
  ];

  await startTourIfNeeded(
    steps: tourSteps,
    hasSeenTour: TourPreferences.hasSeenFaceScanTour,
    markTourAsSeen: TourPreferences.markFaceScanTourAsSeen,
    onComplete: () {
      debugPrint('Face scan tour completed!');
    },
  );
}
```

## Advanced Customization

### Custom Tooltip Positioning
Control where tooltips appear relative to highlighted elements:

```dart
createTourStep(
  title: 'Your Title',
  description: 'Your description',
  targetKey: _yourKey,
  tooltipAlignment: Alignment.topCenter,  // Show above element
  tooltipOffset: EdgeInsets.only(bottom: 20),  // 20px above
)
```

### Tour Management
```dart
// Check if tour was seen
final hasSeenTour = await TourPreferences.hasSeenFaceScanTour();

// Reset tour (for testing)
await TourPreferences.resetFaceScanTour();

// Mark tour as seen manually
await TourPreferences.markFaceScanTourAsSeen();
```

## Testing the Tour

### During Development
Add a debug button to reset the tour:

```dart
// Add this button in your debug builds
ElevatedButton(
  onPressed: () {
    FaceScanTourDebugHelper.resetTour(context);
  },
  child: Text('Reset Tour'),
)
```

### Testing Scenarios
1. **First time user**: Tour should appear automatically
2. **Returning user**: Tour should not appear
3. **Skip functionality**: User can skip at any step
4. **Navigation**: Previous/Next buttons work correctly
5. **Completion**: Tour marks as seen after completion

## Customization Options

### Styling
Modify the tour appearance by editing `guided_tour_overlay.dart`:

- **Background dim**: Adjust `Colors.black.withValues(alpha: 0.7)`
- **Tooltip colors**: Modify container decoration in `_buildTooltipContent()`
- **Highlight border**: Change border styling in `_HighlightPainter`
- **Animation duration**: Adjust `Duration(milliseconds: 300)`

### Tour Steps
Each step can have:

- **title**: Short heading
- **description**: Detailed explanation
- **targetKey**: Widget to highlight
- **tooltipAlignment**: Where tooltip appears
- **tooltipOffset**: Fine-tune tooltip position

### SharedPreferences Keys
The tour uses these keys (modify in `TourPreferences` if needed):

- `has_seen_face_scan_tour`: Boolean flag for face scan tour

## Best Practices

1. **Delay initialization**: Use `addPostFrameCallback` to ensure widgets are built
2. **Check mounted**: Always verify widget is still mounted before async operations
3. **Clear descriptions**: Keep tooltip text concise but informative
4. **Logical flow**: Order steps to match natural user workflow
5. **Test thoroughly**: Verify tour works on different screen sizes

## Common Issues & Solutions

### Tour not appearing
- Ensure keys are properly assigned to widgets
- Check that `hasSeenTour()` returns false for first-time users
- Verify `addPostFrameCallback` is used for initialization

### Tooltip positioning issues
- Adjust `tooltipOffset` values
- Try different `tooltipAlignment` options
- Consider screen size and element positions

### Animation glitches
- Increase delay in `addPostFrameCallback`
- Ensure target widgets are fully rendered before starting tour

### Memory leaks
- The overlay automatically cleans up when tour completes
- No manual cleanup required