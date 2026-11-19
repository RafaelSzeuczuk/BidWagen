import 'package:flutter/material.dart';

SnackBar avisoOfflineSnackBar() => const SnackBar(
      content: Text(
        'Você está offline.',
        style: TextStyle(color: Colors.redAccent),
      ),
    );
