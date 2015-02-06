# askascii
A twitter client that converts images to ASCII. Tweet an image or image link to @askascii, and it will reply with an ASCII art version of your image.

The script looks for a file named `config.yaml` in the project directory that contains the twitter OAuth tokens:

    twitter:
      consumer_key: THE_CONSUMER_KEY
      consumer_secret: THE_CONSUMER_SECRET
      access_token: THE_ACCESS_TOKEN
      access_token_secret: THE_ACCESS_TOKEN_SECRET

## Dependencies

* [ImageMagick](http://imagemagick.org/)
* [jp2a](https://csl.name/jp2a/)
* [phantomjs](http://phantomjs.org/)
