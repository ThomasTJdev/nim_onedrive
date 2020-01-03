# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
from base64 import encode

import onedrive

const publicUrl = "https://publicurl.com"
let accessUrl = encode(publicUrl)


test "encodeUrl":
  check encode(publicUrl) == "aHR0cHM6Ly9wdWJsaWN1cmwuY29t"


