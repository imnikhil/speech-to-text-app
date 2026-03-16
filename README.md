# Speech-to-Text App

This is a basic Speech-to-Text application that converts spoken audio to text.

## Features

*   Converts spoken audio to text.

## Getting Started

### Prerequisites

*   Python 3.x installed
*   `pip` package manager

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/imnikhil/speech-to-text-app.git
    cd speech-to-text-app
    ```

2.  **Install dependencies:**
    The project includes an `install.sh` script to handle dependency installation. Run it from your terminal.
    ```bash
    sh install.sh
    ```
    *(Note: Ensure `install.sh` is executable `chmod +x install.sh` if it's not already.)*

3.  **Python Environment (Recommended):**
    It's highly recommended to use a virtual environment to manage Python dependencies.
    ```bash
    python3 -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
    ```
    Then run the install script within your activated virtual environment:
    ```bash
    sh install.sh
    ```

### Usage

To run the application, use the following command:

```bash
python main.py
```

This will start the speech-to-text conversion process.

## Contributing

If you would like to contribute to this project, please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.