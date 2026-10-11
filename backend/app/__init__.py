from flask import Flask
from flask_cors import CORS

from app.config import Config
from app.routes.api import api_blueprint


def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)

    CORS(
        app,
        resources={r"/api/*": {"origins": Config.CORS_ORIGINS}},
        allow_headers=["Content-Type", "Authorization"],
        methods=["GET", "POST", "OPTIONS"],
    )

    app.register_blueprint(api_blueprint, url_prefix="/api")
    return app
