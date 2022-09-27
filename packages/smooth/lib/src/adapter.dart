import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:smooth/src/auxiliary_tree.dart';

class AdapterInMainTreeWidget extends SingleChildRenderObjectWidget {
  final AuxiliaryTreePack pack;

  const AdapterInMainTreeWidget({
    super.key,
    required this.pack,
    super.child,
  });

  @override
  RenderAdapterInMainTree createRenderObject(BuildContext context) =>
      RenderAdapterInMainTree(
        pack: pack,
      );

  @override
  void updateRenderObject(
      BuildContext context, RenderAdapterInMainTree renderObject) {
    renderObject.pack = pack;
  }
}

class RenderAdapterInMainTree extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  RenderAdapterInMainTree({
    required this.pack,
  });

  AuxiliaryTreePack pack;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // ref: RenderProxyBox
    return child?.hitTest(result, position: position) ?? false;
  }

  @override
  void performLayout() {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    // print('$runtimeType.performLayout start');

    // NOTE
    pack.rootView.configuration =
        AuxiliaryTreeRootViewConfiguration(size: constraints.biggest);

    // https://github.com/fzyzcjy/yplusplus/issues/5815#issuecomment-1256952866
    // NOTE need to be *after* setting pack.rootView.configuration
    // hack, just for prototype
    final lastVsyncInfo = binding.lastVsyncInfo();
    pack.runPipeline(lastVsyncInfo.vsyncTargetTimeAdjusted,
        debugReason: '$runtimeType.performLayout');

    // print('$runtimeType.performLayout child.layout start');
    child!.layout(constraints);
    // print('$runtimeType.performLayout child.layout end');

    size = constraints.biggest;
  }

  // TODO correct?
  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(offset == Offset.zero,
        '$runtimeType prototype has not deal with offset yet');

    // print('$runtimeType.paint called');

    // ref: RenderOpacity

    // TODO this makes "second tree root layer" be *removed* from its original
    //      parent. shall we move it back later? o/w can be slow!
    final auxiliaryTreeRootLayer = pack.rootView.layer!;

    // print(
    //     'just start auxiliaryTreeRootLayer=${auxiliaryTreeRootLayer.toStringDeep()}');

    // HACK!!!
    if (auxiliaryTreeRootLayer.attached) {
      print('$runtimeType.paint detach the auxiliaryTreeRootLayer');
      // TODO attach again later?
      auxiliaryTreeRootLayer.detach();
    }

    // printWrapped('$runtimeType.paint before addLayer');
    // printWrapped('pack.rootView.layer=${pack.rootView.layer?.toStringDeep()}');
    // printWrapped(
    //     'pack.element.renderObject=${pack.element.renderObject.toStringDeep()}');

    // print('$runtimeType.paint addLayer');
    // NOTE addLayer, not pushLayer!!!
    context.addLayer(auxiliaryTreeRootLayer);
    // context.pushLayer(auxiliaryTreeRootLayer, (context, offset) {}, offset);

    // print('auxiliaryTreeRootLayer.attached=${auxiliaryTreeRootLayer.attached}');
    // printWrapped(
    //     'after addLayer auxiliaryTreeRootLayer=${auxiliaryTreeRootLayer.toStringDeep()}');

    // ================== paint those child in main tree ===================

    // NOTE do *not* have any relation w/ self's PaintingContext, as we will not paint there
    {
      // ref: [PaintingContext.pushLayer]
      if (pack.mainSubTreeLayerHandle.layer!.hasChildren) {
        pack.mainSubTreeLayerHandle.layer!.removeAllChildren();
      }
      final childContext = PaintingContext(
          pack.mainSubTreeLayerHandle.layer!, context.estimatedBounds);
      child!.paint(childContext, Offset.zero);
      // ignore: invalid_use_of_protected_member
      childContext.stopRecordingIfNeeded();
    }

    // =====================================================================
  }
}

class AdapterInAuxiliaryTreeWidget extends SingleChildRenderObjectWidget {
  final AuxiliaryTreePack pack;

  const AdapterInAuxiliaryTreeWidget({
    super.key,
    required this.pack,
    super.child,
  });

  @override
  RenderAdapterInAuxiliaryTree createRenderObject(BuildContext context) =>
      RenderAdapterInAuxiliaryTree(
        pack: pack,
      );

  @override
  void updateRenderObject(
      BuildContext context, RenderAdapterInAuxiliaryTree renderObject) {
    renderObject.pack = pack;
  }
}

class RenderAdapterInAuxiliaryTree extends RenderBox {
  RenderAdapterInAuxiliaryTree({
    required this.pack,
  });

  AuxiliaryTreePack pack;

  @override
  void performLayout() {
    // print('$runtimeType.performLayout called');
    size = constraints.biggest;
  }

  // TODO correct?
  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(offset == Offset.zero,
        '$runtimeType prototype has not deal with offset yet');

    // printWrapped('$runtimeType.paint before addLayer');
    // printWrapped(
    //     'pack.mainSubTreeLayerHandle.layer=${pack.mainSubTreeLayerHandle.layer?.toStringDeep()}');

    // print('$runtimeType paint');

    context.addLayer(pack.mainSubTreeLayerHandle.layer!);
    // context.addLayer(_simpleLayer.layer!);
  }
}

// final _simpleLayer = () {
//   final recorder = PictureRecorder();
//   final canvas = Canvas(recorder);
//   final rect = Rect.fromLTWH(0, 0, 200, 200);
//   canvas.drawRect(Rect.fromLTWH(0, 0, 50, 100), Paint()..color = Colors.red);
//   final pictureLayer = PictureLayer(rect);
//   pictureLayer.picture = recorder.endRecording();
//   final wrapperLayer = OffsetLayer();
//   wrapperLayer.append(pictureLayer);
//
//   return LayerHandle(wrapperLayer);
// }();
