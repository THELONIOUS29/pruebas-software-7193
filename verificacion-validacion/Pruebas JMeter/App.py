from flask import Flask, request, jsonify
app = Flask(__name__)
@app.route('/saludo', methods=['GET'])
def saludo():
    return jsonify({'mensaje':'Hola mundo'})
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    if data['usuario']=='admin' and data['password']=='1234':
        return jsonify({'mensaje':'Login exitoso'}),200
    return jsonify({'mensaje':'Error'}),401
if __name__=='__main__':
    app.run(debug=True)
