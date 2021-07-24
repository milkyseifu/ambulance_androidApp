import 'package:amblance/front_page.dart';
import 'package:amblance/map_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  PageController _pageController = PageController();
  List<Widget> _screen = [
    // FrontPage()
  ];
  int _selectedIndex = 0;
  void _onPageChanged(int index){
    setState(() {
      _selectedIndex = index;
    });
  }
  void _onItemTapped(int selectedIndex){
    _pageController.jumpToPage(selectedIndex);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      body: PageView(
        controller: _pageController,
        children: _screen,
        onPageChanged: _onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Color.fromRGBO(58, 66, 86, 1.0),
          primaryColor: Colors.red,
          textTheme: Theme.of(context).textTheme.
            copyWith(caption: new TextStyle(color: Colors.yellow))
        ),
        child: BottomNavigationBar(
          onTap: _onItemTapped,
          items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home,
                    color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
              ),
              title: Text('Home',
                  style: TextStyle(
                    color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                  ),
              )),
          BottomNavigationBarItem(
              icon: Icon(Icons.map,
                    color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
              ),
              title: Text('Map',
                    style: TextStyle(
                      color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                    ),
              )),
        ],),
      ),
    );
  }
}
