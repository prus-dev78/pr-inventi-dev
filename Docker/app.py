from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Hello World</title>
        <style>
            body {
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background-color: white;
                font-family: Arial, sans-serif;
            }
            h1 {
                color: black;
                font-size: 48px;
            }
        </style>
    </head>
    <body>
        <h1>Hello world!</h1>
    </body>
    </html>
    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)