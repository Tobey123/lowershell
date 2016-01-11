from Crypto.Cipher import AES
from Crypto import Random


class Crypt(object):   
    def __init__(self, key):
        super(Crypt, self).__init__()
        sha = hashlib.sha256()
        sha.update(key)
        self.key = sha.digest()

    def pad(self, s):
        BS = AES.block_size
        return s + (BS - len(s) % BS) * chr(BS - len(s) % BS)

    def unpad(self, s):
        return s[0:-ord(s[-1])]

    def encrypt(self, buf):
        raw = self.pad(buf)
        iv = Random.new().read(AES.block_size)
        aes = AES.new(self.key, AES.MODE_CBC, iv)
        return iv + aes.encrypt(raw)

    def decrypt(self, buf):
        iv = buf[0:AES.block_size]
        cipher = buf[AES.block_size:]
        aes = AES.new(self.key, AES.MODE_CBC, iv)
        raw = aes.decrypt(cipher)
        return self.unpad(raw)