from PIL import Image

import sys
import os.path


base64_lookup = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'


def steg(payload, image, output):
    with open(payload, 'rb') as payload_file, \
            open(image, 'rb') as image_file, \
            open(output, 'rw') as output_file
        
        image_carrier = Image.open(image_file)
        image_merged = Image.open(output_file)

        capacity = image_carrier.size
        payload_size = os.path.getsize(payload)
        if payload_size > capacity:
            raise ValueError('Image capacity exceed. Try a nother carrier.')





if __name__ == '__main__':
    if len(sys.argv) != 4:
        print 'Usage: %s payload image output' % os.path.basename(sys.argv[0])
    else:
        steg(*sys.argv[1:])
