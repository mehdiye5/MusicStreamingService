from wsgiref import headers
import requests


class Playlist:
    def __init__(self, url, auth):
        self._url = url
        self._auth = auth

    def create_playlist(self, playlist_name, genre, songs):
        r = requests.post(
            self._url,
            json={"playlist_name": playlist_name, "genre": genre, "songs": songs},
            headers={"Authorization": self._auth},
        )
        return r.status_code, r.json()["playlist_id"]

    def read_playlist(self, playlist_id):
        r = requests.get(self._url + playlist_id, headers={"Authorization": self._auth})
        if r.status_code != 200:
            return r.status_code, None, None, None

        item = r.json()["Items"][0]
        return (
            r.status_code,
            item["Artist"],
            item["playlist_name"],
            item["genre"],
            item["songs"],
        )

    def delete(self, playlist_id):
        requests.delete(self._url + playlist_id, headers={"Authorization": self._auth})
