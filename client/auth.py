import hashlib


def auth_code(uid):
    # todo: database
    if uid == '8fd2d4d2-1385-4b66-b4da-00191f6ee044':
        sha = hashlib.sha256()
        sha.update(uid)
        sha.update(SECRET)
        digest = sha.digest()
        sha = hashlib.sha256()
        sha.update(digest)
        sha.update(SECRET)
        return sha.hexdigest()
