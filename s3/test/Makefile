# Makefile for test of Playlist service (S3)

VER=v0.8

SERVER=`docker container inspect s3 --format '{{.NetworkSettings.IPAddress}}'`

build-playlist_test:
	docker image build -f Dockerfile -t playlist_test:$(VER) .

# Do not use '-it' options because this will run in non-TTY environment as GitHub Action
run-music_test:
	docker container run --rm --name playlist_test playlist_test:$(VER) python3 playlist_test.py $(SERVER) 30003
