# Tirecheck Device SDK Flutter

This app is for testing of Tirecheck Device SDK Flutter.
It intergrates the plugin with flutter_blue_plus.

## How to run

To run the Tirecheck Device SDK Flutter app, follow these steps:

1. **Request Access**
    Before to use tirecheck-device-sdk-flutter, you will need to request access. Please, contact [jakub.suchy@gmail.com](mailto:jakub.suchy@tirecheck.com?subject=GitHub%20access%20request%20-%20tirecheck-device-sdk&body=Please%2C%20could%20you%20give%20me%20access%20to%20tirecheck-device-sdk%20project%20on%20GitHub%3F%0A%0ACompany%3A%20%5Byour%20company%20name%5D%0AGithub%20username%3A%20%5Byour%20github%20username%5D%0A%0AThank%20you!)

2. **Install Dependencies**: Run the following command to install the required dependencies. Please note that we use OnePub for dependency.

    ```sh
    flutter pub get
    ```

3. **Run the App**: Use the following command to run the app on your connected device or emulator.

    ```sh
    flutter run
    ```

4. **Build the App**: If you want to build the app for a specific platform, use the following commands:

    - For Android:

        ```sh
        flutter build apk
        ```

    - For iOS:

        ```sh
        flutter build ios
        ```

Make sure you have a device connected or an emulator running before executing the `flutter run` command. For more details, refer to the [Flutter documentation](https://flutter.dev/docs/get-started/test-drive).