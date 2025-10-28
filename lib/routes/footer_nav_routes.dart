import 'package:flutter/material.dart';

class FooterNav extends StatelessWidget { // Change to StatelessWidget
  final int selectedIndex;
  final Function(int) onItemTapped;

  const FooterNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Remove the "Footer Nav" label if it's not part of the final design
        // or integrate it differently if it's meant as a debugging label.
        // For now, removing to match common app layouts.
        // const Padding(
        //   padding: EdgeInsets.all(8.0),
        //   child: Align(
        //     alignment: Alignment.centerLeft,
        //     child: Row(
        //       children: [
        //         Icon(
        //           Icons.star, // Using a star icon as a placeholder for the diamond
        //           color: Colors.deepPurple,
        //           size: 20,
        //         ),
        //         SizedBox(width: 4),
        //         Text(
        //           'Footer Nav',
        //           style: TextStyle(
        //             color: Colors.deepPurple,
        //             fontSize: 18,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey,
            currentIndex: selectedIndex, // Use the passed selectedIndex
            onTap: onItemTapped,         // Use the passed onItemTapped
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan / Pay',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.coffee),
                label: 'Order',
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.star_border),
                label: 'Rewards',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        ),
        Container(
          height: 5,
          width: 130,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.only(bottom: 8),
        ),
      ],
    );
  }
}