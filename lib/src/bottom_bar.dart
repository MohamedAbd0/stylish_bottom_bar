import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../stylish_bottom_bar.dart';
import 'anim_nav/animated_nav_tiles.dart';
import 'bubble_nav_bar/bubble_navigation_tile.dart';
import 'bubble_nav_bar/cliper.dart';
import 'helpers/constant.dart';
import 'widgets/widgets.dart';
import 'dart:math' as math;

// ignore: must_be_immutable
class StylishBottomBar extends StatefulWidget {
  StylishBottomBar({
    Key? key,
    required this.items,
    this.iconStyle,
    this.backgroundColor,
    this.elevation,
    this.currentIndex = 0,
    this.iconSize = 26.0,
    this.padding = EdgeInsets.zero,
    this.inkEffect = false,
    this.inkColor = Colors.grey,
    this.onTap,
    this.opacity = 0.8,
    this.borderRadius,
    this.fabLocation,
    this.hasNotch = false,
    this.barAnimation = BarAnimation.fade,
    //======================//
    //===For bubble style===//
    //======================//
    this.bubbleFillStyle = BubbleFillStyle.fill,
    this.unselectedIconColor = Colors.black,
    this.barStyle = BubbleBarStyle.horizotnal,
  })  : assert(items.length >= 2,
            '\n\nStylish Bottom Navigation must have 2 or more items'),
        assert(
          items.every((dynamic item) => item.title != null) == true,
          '\n\nEvery item must have a non-null title',
        ),
        assert((currentIndex! >= items.length) == false,
            '\n\nCurrent index is out of bond. Provided: $currentIndex  Bond: 0 to ${items.length - 1}'),
        assert((currentIndex! < 0) == false,
            '\n\nCurrent index is out of bond. Provided: $currentIndex  Bond: 0 to ${items.length - 1}'),
        assert(
            (items.every((element) {
                  return element.runtimeType == AnimatedBarItems;
                }) ||
                items.every((element) {
                  return element.runtimeType == BubbleBarItem;
                })),
            '\n\nProvide one of "AnimatedBarItems" or "BubbleBarItem" to items: \n You can not use both inside one List<...>'),
        super(key: key);

  ///Change unselected item color
  ///If you don't want to change every single icon color use this property
  ///this will bulk change all the unselected icon color which does'nt have color property.
  ///
  ///If icon color not provided then
  ///default unselected icon color is [Colors.black]
  ///this is also used to set bulk color to unselected icons
  ///
  ///Only Availble for Bubble Bottom Bar
  final Color? unselectedIconColor;

  ///Use this to customize bubble background fill style
  ///You can use border with [BubbleFillStyle.outlined]
  ///and also fill the background with color using [BubbleFillStyle.fill]
  ///
  ///Only Availble for Bubble Bottom Bar
  final BubbleFillStyle? bubbleFillStyle;

  ///BarStyle to align icon and title in horizontal or vertical
  ///[BubbleBarStyle.horizotnal]
  ///[BubbleBarStyle.vertical]
  ///Default value is [BubbleBarStyle.horizotnal]
  ///
  ///Only Availble for Bubble Bottom Bar
  final BubbleBarStyle? barStyle;

  //==============//
  //==============//

  final List<dynamic> items;
  final Color? backgroundColor;
  final double? elevation;

  final double? iconSize;
  int? currentIndex;
  final EdgeInsets? padding;
  final bool? inkEffect;
  final bool hasNotch;

  final Color? inkColor;
  final ValueChanged<int?>? onTap;
  final double? opacity;
  final BorderRadius? borderRadius;
  final StylishBarFabLocation? fabLocation;
  final BarAnimation? barAnimation;
  final IconStyle? iconStyle;

  @override
  _StylishBottomBarState createState() => _StylishBottomBarState();
}

class _StylishBottomBarState extends State<StylishBottomBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers = <AnimationController>[];
  late List<CurvedAnimation> _animations;
  Color? _backgroundColor;

  ValueListenable<ScaffoldGeometry>? _geometryListenable;
  Animatable<double>? _flexTween;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _geometryListenable = Scaffold.geometryOf(context);
    _flexTween = widget.hasNotch
        ? Tween<double>(begin: 1.15, end: 2.0)
        : Tween<double>(begin: 1.15, end: 1.75);
  }

  void _state() {
    for (AnimationController controller in _controllers) controller.dispose();

    _controllers =
        List<AnimationController>.generate(widget.items.length, (int index) {
      return AnimationController(
        duration: Duration(milliseconds: 200),
        vsync: this,
      )..addListener(() {
          setState(() {});
        });
    });
    _animations =
        List<CurvedAnimation>.generate(widget.items.length, (int index) {
      return CurvedAnimation(
        parent: _controllers[index],
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped,
      );
    });
    _controllers[widget.currentIndex!].value = 1.0;
    _backgroundColor = widget.items[widget.currentIndex!].backgroundColor;
  }

  @override
  void initState() {
    super.initState();
    _state();
  }

  @override
  void dispose() {
    ///Dispose controllers
    for (AnimationController controller in _controllers) controller.dispose();
    super.dispose();
  }

  double _evaluateFlex(Animation<double> animation) =>
      _flexTween!.evaluate(animation);

  @override
  void didUpdateWidget(StylishBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.length != oldWidget.items.length) {
      _state();
      return;
    }

    if (widget.currentIndex != oldWidget.currentIndex) {
      _controllers[oldWidget.currentIndex!].reverse();
      _controllers[widget.currentIndex!].forward();

      if (widget.fabLocation == StylishBarFabLocation.center) {
        dynamic _currentItem = widget.items[oldWidget.currentIndex!];
        dynamic _nextItem = widget.items[widget.currentIndex!]!;

        widget.items[0] = _nextItem;
        widget.items[widget.currentIndex!] = _currentItem;
        _controllers[oldWidget.currentIndex!].reverse();
        _controllers[widget.currentIndex!].forward();
        widget.currentIndex = 0;
        _state();
      }
    } else {
      if (_backgroundColor !=
          widget.items[widget.currentIndex!].backgroundColor)
        _backgroundColor = widget.items[widget.currentIndex!].backgroundColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    var additionalBottomPadding, listWidget;

    if (widget.items[0].runtimeType == AnimatedBarItems) {
      additionalBottomPadding =
          math.max(MediaQuery.of(context).padding.bottom - BottomMargin, 0.0) +
              2;
      listWidget = _animatedBarChilds();
    } else if (widget.items[0].runtimeType == BubbleBarItem) {
      additionalBottomPadding =
          math.max(MediaQuery.of(context).padding.bottom - BottomMargin, 0.0) +
              4;
      listWidget = _bubbleBarTiles();
    }

    return Semantics(
      explicitChildNodes: true,
      child: widget.hasNotch
          ? PhysicalShape(
              elevation: widget.elevation ?? 8.0,
              color: widget.backgroundColor ?? Colors.white,
              clipper: BubbleBarClipper(
                shape: CircularNotchedRectangle(),
                geometry: _geometryListenable!,
                notchMargin: 8,
              ),
              child: innerWidget(context, additionalBottomPadding,
                  widget.fabLocation, listWidget, widget.barAnimation!),
            )
          : Material(
              elevation: widget.elevation ?? 8.0,
              color: widget.backgroundColor != null
                  ? widget.backgroundColor
                  : Colors.white,
              child: innerWidget(context, additionalBottomPadding + 2,
                  widget.fabLocation, listWidget, widget.barAnimation!),
              borderRadius: widget.borderRadius != null
                  ? widget.borderRadius
                  : BorderRadius.zero,
            ),
    );
  }

  List<Widget> _bubbleBarTiles() {
    final MaterialLocalizations? localizations =
        MaterialLocalizations.of(context);
    assert(localizations != null);
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < widget.items.length; i += 1) {
      children.add(
        BubbleNavigationTile(
          widget.items[i],
          widget.opacity!,
          _animations[i],
          widget.iconSize!,
          widget.unselectedIconColor,
          widget.barStyle,
          onTap: () {
            if (widget.onTap != null) widget.onTap!(i);
          },
          selected: i == widget.currentIndex,
          flex: _evaluateFlex(_animations[i]),
          indexLabel: localizations!
              .tabLabel(tabIndex: i + 1, tabCount: widget.items.length),
          ink: widget.inkEffect!,
          inkColor: widget.inkColor,
          padding: widget.padding,
          fillStyle: widget.bubbleFillStyle,
        ),
      );
    }

    if (widget.fabLocation == StylishBarFabLocation.center) {
      children.insert(
          1,
          Spacer(
            flex: 1500,
          ));
    }
    return children;
  }

  List<Widget> _animatedBarChilds() {
    final List<Widget> list = [];
    final MaterialLocalizations? localizations =
        MaterialLocalizations.of(context);

    for (int i = 0; i < widget.items.length; i += 1) {
      list.add(AnimatedNavigationTiles(
        widget.items[i],
        widget.iconSize!,
        widget.padding!,
        inkEffect: widget.inkEffect,
        inkColor: widget.inkColor,
        selected: widget.currentIndex == i,
        opacity: widget.opacity!,
        animation: _animations[i],
        barAnimation: widget.barAnimation!,
        iconStyle: widget.iconStyle ?? IconStyle.animated,
        onTap: () {
          if (widget.onTap != null) widget.onTap!(i);
        },
        flex: _evaluateFlex(_animations[i]),
        indexLabel: localizations!
            .tabLabel(tabIndex: i + 1, tabCount: widget.items.length),
      ));
    }
    if (widget.fabLocation == StylishBarFabLocation.center) {
      list.insert(
          1,
          Spacer(
            flex: 2,
          ));
    }
    return list;
  }
}