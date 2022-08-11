"""
SFU CMPT 756
Sample STANDALONE application---playlist service.
"""

# Standard library modules
import csv
import logging
import os
import sys
import uuid
import json
import traceback

# Installed packages
from flask import Blueprint
from flask import Flask
from flask import request
from flask import Response

from prometheus_flask_exporter import PrometheusMetrics

import requests

import simplejson as json

PERCENT_ERROR = 50
ucode = 123
# The application

app = Flask(__name__)

metrics = PrometheusMetrics(app)
metrics.info("app_info", "Playlist process")

db = {
    "name": "http://cmpt756db:30002/api/v1/datastore",
    "endpoint": ["read", "write", "delete", "update"],
}

bp = Blueprint("app", __name__)


@bp.route("/health")
@metrics.do_not_track()
def health():
    return Response("", status=200, mimetype="application/json")


@bp.route("/readiness")
@metrics.do_not_track()
def readiness():
    return Response("", status=200, mimetype="application/json")


@bp.route("/", methods=["GET"])
def list_all():
    headers = request.headers
    if "Authorization" not in headers:
        return Response(
            json.dumps({"error": "missing auth"}),
            status=401,
            mimetype="application/json",
        )
    return {}


@bp.route("/<UUID>", methods=["GET"])
def read_playlist(UUID):
    headers = request.headers
    if "Authorization" not in headers:
        return Response(
            json.dumps({"error": "missing auth"}),
            status=401,
            mimetype="application/json",
        )
    payload = {"objtype": "playlist", "objkey": UUID}
    url = db["name"] + "/" + db["endpoint"][0]
    response = requests.get(
        url, params=payload, headers={"Authorization": headers["Authorization"]}
    )
    return response.json()


@bp.route("/", methods=["POST"])
def create_playlist():
    headers = request.headers
    if "Authorization" not in headers:
        return Response(
            json.dumps({"error": "missing auth"}),
            status=401,
            mimetype="application/json",
        )
    try:
        content = request.get_json()
        playlistname = content["playlist_name"]
        genre = content["genre"]
        songs = content["songs"]
    except Exception:
        return app.make_response(
            ({"Message": "Error reading arguments"}, 400)
            # (traceback.print_exc(), 400)
        )
    playlist_id = str(uuid.uuid4())
    url = db["name"] + "/" + db["endpoint"][1]
    response = requests.post(
        url,
        json={
            "objtype": "playlist",
            "playlist_name": playlistname,
            "genre": genre,
            "playlist": songs,
            "uuid": playlist_id,
        },
        headers={"Authorization": headers["Authorization"]},
    )
    return response.json()


@bp.route("/<UUID>", methods=["DELETE"])
def delete_playlist(UUID):
    headers = request.headers
    # check header here
    if "Authorization" not in headers:
        return Response(
            json.dumps({"error": "missing auth"}),
            status=401,
            mimetype="application/json",
        )

    url = db["name"] + "/" + db["endpoint"][2]
    response = requests.delete(
        url,
        params={"objtype": "playlist", "objkey": UUID},
        headers={"Authorization": headers["Authorization"]},
    )
    return response.json()


@bp.route("/test", methods=["GET"])
def test():
    # This is a test value set at top of script
    if 123 != ucode:
        raise Exception("Test failed")
    return {}


app.register_blueprint(bp, url_prefix="/api/v1/playlist/")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        logging.error("missing port arg 1")
        sys.exit(-1)

    p = int(sys.argv[1])
    app.run(host="0.0.0.0", port=p, threaded=True)
