# MagnifyingGlass Flutter plugin

Flutter real-time magnifying glass lens widget with Barrel/Pincushion distortion.
Works on Android, iOS and desktop. Doesn't work yet on web (help needed with web FFI).

![Screenshot](https://github.com/alnitak/magnifying_glass/blob/master/img/magnifying_glass.gif?raw=true "Magnifying Glass Demo")

<a href="https://www.buymeacoffee.com/marcobavag" target="_blank"><img align="left" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a><br/><br/>

## Getting Started

Make [MagnifyingGlass] widget as the parent of the widget you wish to be used (usually MyHomePage).

```dart
    @override
    Widget build(BuildContext context) {
    MagnifyingGlassController magnifyingGlassController = MagnifyingGlassController();
    return MagnifyingGlass(
      controller: magnifyingGlassController,
      glassPosition: GlassPosition.touchPosition,
      borderThickness: 8.0,
      borderColor: Colors.grey,
      glassParams: GlassParams(
        startingPosition: Offset(150, 150),
        diameter: 150,
        distortion: 1.0,
        magnification: 1.2,
        padding: EdgeInsets.all(10),
      ),
      child: Scaffold( 
        body: ...,

        floatingActionButton: FloatingActionButton(
          onPressed: () => magnifyingGlassController.openGlass(),
          child: const Icon(Icons.search),
        ),
      )
    );
```

## MagnifyingGlass properties

|Name|Type|Description|
|:-------|:----------|:-----------|
**controller**|MagnifyingGlassController|Let you control the glass state and parameters: <br>**openGlass()**<br>**closeGlass()**<br>**setDistortion(** *double distortion, double magnification* **)**<br>**setDiameter(** *int diameter* **)**|
**glassPosition**|enum|enum to set the touch behavior or sticky position|
**glassParams**|GlassParams|class to set lens parameters|
**borderColor**|Color|border color|
**borderThickness**|double|border thickness|
**elevation**|double|shadow elevation|
**shadowOffset**|Offset|shadow offset|

<br>

**GlassPosition class**

|Name|Description|
|:-------|:-----------|
**touchPosition**|move the glass with finger touch|
**topLeft**|sticky position to top left corner of the screen|
**topRight**|sticky position to top rigth corner of the screen|
**bottomLeft**|sticky position to bottom left corner of the screen|
**bottomRight**|sticky position to bottom right corner of the screen|

<br>

**GlassParams class**

|Name|Description|
|:-------|:-----------|
**startingPosition**|the startin glass position. If not given the lens will be placed at the center of the screen.|
**diameter**|the diameter of the glass|
**magnification**|the magnification of the lens<br>1 means no magnification<br>>1 means magnification<br><1 means shrinking|
**distortion**|Barrel/Pincushion distortion power<br>0 means no distortion|
**padding**|the padding surrounding the glass to enlarge touching area|

| ![distorsion0.5-mag1.0.png](https://github.com/alnitak/magnifying_glass/blob/master/img/distorsion0.5-mag1.0.png?raw=true) | ![distorsion0.5-mag1.4.png](https://github.com/alnitak/magnifying_glass/blob/master/img/distorsion0.5-mag1.4.png?raw=true) | ![distorsion2.0-mag1.7.png](https://github.com/alnitak/magnifying_glass/blob/master/img/distorsion2.0-mag1.7.png?raw=true) | 
|:--:|:--:|:--:|
| *distorsion 0.5 <br> mag 1.0* | *distorsion 0.5 <br> mag 1.4* | *distorsion 2.0 <br> mag 1.7* |

