import 'package:flutter/material.dart';
import 'package:magnifying_glass/magnifying_glass.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  ValueNotifier<int> diameter = ValueNotifier(150);
  ValueNotifier<double> distortion = ValueNotifier(1.0);
  ValueNotifier<double> magnification = ValueNotifier(1.2);
  ValueNotifier<GlassPosition> glassPosition = ValueNotifier(GlassPosition.touchPosition);

  @override
  Widget build(BuildContext context) {
    MagnifyingGlassController magnifyingGlassController = MagnifyingGlassController();
    return MagnifyingGlass(
      controller: magnifyingGlassController,
      glassPosition: glassPosition.value,
      glassParams: GlassParams(
        // startingPosition: Offset(150, 150),
        diameter: diameter.value,
        distortion: distortion.value,
        magnification: magnification.value,
        padding: EdgeInsets.all(10),
      ),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset('assets/dash.png'),

              /// Diameter
              Row(
                children: [
                  Text('Diameter'),
                  ValueListenableBuilder<int>(
                    valueListenable: diameter,
                    builder: (_, _diameter, __) {
                      return Expanded(
                        child: Slider(
                          value: _diameter.toDouble(),
                          min: 10,
                          max: 300,
                          divisions: 29,
                          label: diameter.value.toString(),
                          onChanged: (value) {
                            diameter.value = value.toInt();
                            magnifyingGlassController.setDiameter(diameter.value);
                          }
                        ),
                      );
                    }
                  ),
                ],
              ),

              /// Distortion
              Row(
                children: [
                  Text('Distortion'),
                  ValueListenableBuilder<double>(
                    valueListenable: distortion,
                    builder: (_, _distortion, __) {
                      return Expanded(
                        child: Slider(
                          value: _distortion,
                          min: -3.0,
                          max: 3.0,
                          divisions: 60,
                          label: distortion.value.toStringAsFixed(2),
                          onChanged: (value) {
                            distortion.value = value;
                            magnifyingGlassController.setDistortion(distortion.value, magnification.value);
                          }
                        ),
                      );
                    }
                  ),
                ],
              ),

              /// Magnification
              Row(
                children: [
                  Text('Magnification'),
                  ValueListenableBuilder<double>(
                    valueListenable: magnification,
                    builder: (_, _magnification, __) {
                      return Expanded(
                        child: Slider(
                          value: _magnification,
                          min: -2.0,
                          max: 2.0,
                          divisions: 100,
                          label: magnification.value.toStringAsFixed(2),
                          onChanged: (value) {
                            magnification.value = value;
                            magnifyingGlassController.setDistortion(distortion.value, magnification.value);
                          }
                        ),
                      );
                    }
                  ),
                ],
              ),

              /// Glass Position top
              ValueListenableBuilder<GlassPosition>(
                valueListenable: glassPosition,
                builder: (_, _glassPosition, __) {
                  return Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _glassPosition == GlassPosition.topLeft,
                        onChanged: (bool? value) {
                          glassPosition.value = GlassPosition.topLeft;
                          setState(() {});
                        },
                      ),
                      Checkbox(
                        value: _glassPosition == GlassPosition.topRight,
                        onChanged: (bool? value) {
                          glassPosition.value = GlassPosition.topRight;
                          setState(() {});
                        },
                      ),
                    ],
                  );
                }
              ),

              /// Glass Position touch
              ValueListenableBuilder<GlassPosition>(
                valueListenable: glassPosition,
                builder: (_, _glassPosition, __) {
                  return Checkbox(
                    value: _glassPosition == GlassPosition.touchPosition,
                    onChanged: (bool? value) {
                      glassPosition.value = GlassPosition.touchPosition;
                      setState(() {});
                    },
                  );
                }
              ),

              /// Glass Position top
              ValueListenableBuilder<GlassPosition>(
                  valueListenable: glassPosition,
                  builder: (_, _glassPosition, __) {
                    return Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _glassPosition == GlassPosition.bottomLeft,
                          onChanged: (bool? value) {
                            glassPosition.value = GlassPosition.bottomLeft;
                            setState(() {});
                          },
                        ),
                        Checkbox(
                          value: _glassPosition == GlassPosition.bottomRight,
                          onChanged: (bool? value) {
                            glassPosition.value = GlassPosition.bottomRight;
                            setState(() {});
                          },
                        ),
                      ],
                    );
                  }
              ),

              const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                    'Phasellus dictum maximus tortor ac porta. Aenean aliquet '
                    'erat eu mi commodo, ut feugiat enim consectetur. ',
                textScaleFactor: 1.3,
                textAlign: TextAlign.justify,
              ),

            ]
          ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () => magnifyingGlassController.openGlass(),
          child: const Icon(Icons.search),
        ),
      ),
    );
  }
}
