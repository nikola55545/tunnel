import 'package:flutter/material.dart';

// ignore: must_be_immutable, camel_case_types
class verification_code extends StatelessWidget {
  final String verificationId;

  // Constructor to receive the verificationId from the previous screen
  verification_code(this.verificationId, {super.key});

  String enteredCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Verification Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can use a TextFormFiel to take input for the verification code
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Verification Code',
              ),
              // Implement the code to save the verification code entered by the user
              onChanged: (value) {
                // Save the entered code to a variable (e.g., enteredCode)
                // You can use the enteredCode later for phone sign-in
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement the code to perform phone sign-in with the enteredCode
                // You can use the verificationId and enteredCode to create PhoneAuthCredential
                // Similar to the codeSent callback in _signInWithPhone() method
                // Once the user is signed in, you can navigate to the main screen or handle it as needed
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
