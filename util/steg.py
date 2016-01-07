from PIL import Image

import sys
import os
import base64
import string
import re


def fakever(n):
  def nums(num):
    base = int(num ** 0.5)
    yield base
    while num:
      yield num % base
      num //= base

  ver = map(str, nums(n)) if n >= 4 else (str(n), '1')
  return '.'.join(ver)[::-1] 


# def decode_fakever(ver):
#   base, *parts = map(int, ver[::-1].split('.'))
#   val = 0
#   while len(parts):
#     val *= base
#     val += parts.pop()
  
#   return val


def steg(payload, image, output):
  '''
  Save payload in image and store payload length in "F Number" exif field

  one bit per channel
  16 pixels for one base64 byte

  @payload hidden data
  @image carrier image
  @output save destination
  '''

  output_basename, output_ext = os.path.splitext(output)
  if output_ext not in ('.png', '.bmp'):
    raise ValueError('You should choose a loseless format for output image like png.')

  base64_lookup = {v:k for k,v in enumerate(
    string.uppercase + string.lowercase + string.digits + '+/')}

  with open(payload, 'rb') as file_payload, open(image, 'rb') as file_image:
    image_carrier = Image.open(file_image)
    capacity = image_carrier.width * image_carrier.height * 3 / 6
    payload_size = os.path.getsize(payload)

    if payload_size > capacity:
      raise ValueError('Image capacity exceed. Try a nother carrier.')
    
    image_carrier = image_carrier.convert('RGB')
    buf = image_carrier.tobytes('raw', 'RGB')
    encoded = re.sub(r'=*$', '', base64.b64encode(file_payload.read()))
    encoded_len = len(encoded)
    
  def blend():
    for offset, ch in enumerate(encoded):
      val = base64_lookup[ch]
      base = offset * 6
      for step in xrange(6): # 64 == 2 ^ 6
        bit = (val >> step) & 1
        yield (ord(buf[base + step]) & 0b11111110) + bit

  merged = ''.join([chr(byte) for byte in blend()]) + buf[encoded_len * 6:]

  image_merged = Image.frombytes(mode='RGB', size=image_carrier.size, data=merged)
  image_merged.save(output)

  os.system('exiftool -Software="FantasyPhoto %s" %s' % (fakever(encoded_len), output))
  print 'Checkout %s' % output
  

if __name__ == '__main__':
  if len(sys.argv) != 4:
    print 'Usage: %s payload image output' % os.path.basename(sys.argv[0])
  else:
    steg(*sys.argv[1:])
