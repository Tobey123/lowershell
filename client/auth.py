import hashlib

from config import REGISTERED


def auth_code(uid):
    # todo: database
    if uid in REGISTERED:
        sha = hashlib.sha256()
        sha.update(uid)
        sha.update(SECRET)
        digest = sha.digest()
        sha = hashlib.sha256()
        sha.update(digest)
        sha.update(SECRET)
        
        return sha.hexdigest()
