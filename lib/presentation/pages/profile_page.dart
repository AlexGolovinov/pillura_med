import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Профили'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              width: 62,
              decoration: BoxDecoration(
                color: Color(0xFFE8EFFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Мой'),
                  Icon(Icons.qr_code_scanner_sharp, size: 35),
                ],
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                'Мои лекарства',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            SizedBox(height: 24),
            // Свайп влево: показывает три кнопки (Удалить, Редактировать, Завершить курс)
            // Требует зависимость: flutter_slidable
            Slidable(
              key: UniqueKey(),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Colors.grey[300], //const Color(0xFFF4F4F4),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  topLeft: Radius.circular(10),
                                ),
                              ),
                              alignment: Alignment.center,
                              //margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: const Icon(
                                Icons.check,
                                size: 32,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Colors.grey[300], //const Color(0xFFF4F4F4),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  topLeft: Radius.circular(10),
                                ),
                              ),
                              alignment: Alignment.center,
                              //margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: const Icon(
                                Icons.edit,
                                size: 32,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Colors.grey[300], //const Color(0xFFF4F4F4),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  topLeft: Radius.circular(10),
                                ),
                              ),
                              alignment: Alignment.center,
                              //margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: const Icon(
                                Icons.delete_forever_rounded,
                                size: 32,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  height: 136,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 19,
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8EFFB),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            topLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Paracetamol',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EFFB),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'по 1 табл.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'c 29 окт.',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC6D649),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                child: const Text(
                                  '10:00',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomAppBar(
      //   height: 70,
      //   shape: CircularNotchedRectangle(),
      //   notchMargin: 8,
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceAround,
      //     children: [
      //       Column(
      //         mainAxisSize: MainAxisSize.min,
      //         children: [Icon(Icons.pie_chart_outline), Text('статистика')],
      //       ),
      //       Column(
      //         children: [Icon(Icons.person_add_outlined), Text('добавить')],
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
