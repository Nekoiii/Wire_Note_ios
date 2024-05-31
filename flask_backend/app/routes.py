from flask import request, jsonify
from app import app
from app.img_to_text import img_to_text


@app.route("/img_to_text", methods=["POST"])
def img_to_text_route():
    return img_to_text(request)
