import 'package:flutter/material.dart';

class MyScaffold extends StatefulWidget {
  Widget _body;
  PreferredSizeWidget? _appBar;
  dynamic _floatingActionButton;
  Widget? _bottomBar;
  bool? resizeToAvoidBottomInset;
  Widget? drawer;
  bool? drawerEnableOpenDragGesture;
  FloatingActionButtonLocation? floatingActionButtonLocation;
  String? backgroundImage;

  MyScaffold(
      {Key? key,
      required Widget body,
      appBar,
      floatingActionButton,
      bottomNavigationBar,
      this.resizeToAvoidBottomInset,
      this.drawer,
      this.drawerEnableOpenDragGesture,
      this.floatingActionButtonLocation,
      this.backgroundImage})
      : this._body = body,
        this._appBar = appBar,
        this._floatingActionButton = floatingActionButton,
        this._bottomBar = bottomNavigationBar,
        super(key: key);

  @override
  State<MyScaffold> createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  @override
  void initState() {
    super.initState();
  }

  dynamic showBackgroundImage() {
    if (widget.backgroundImage != null) {
      return DecorationImage(
        image: AssetImage(widget.backgroundImage!),
        fit: BoxFit.cover,
      );
    }
    return null;
    /*
    if (SSLi.themeBackgroundImage!=null){
      return DecorationImage(
        image: AssetImage(SSLi.themeBackgroundImage),
        fit: BoxFit.cover,
      );
    }else{
      return null;
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        image: showBackgroundImage(),
      ),
      child: Scaffold(
        drawer: widget.drawer,
        drawerEnableOpenDragGesture: widget.drawerEnableOpenDragGesture ?? true,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        backgroundColor: Colors.transparent,
        appBar: widget._appBar,
        body: widget._body,
        floatingActionButton: widget._floatingActionButton,
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
        bottomNavigationBar: widget._bottomBar,
      ),
    );
  }
}
