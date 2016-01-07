$source = @"

using System;
using System.Text;
using System.IO;
using System.Security.Cryptography;

namespace Crypto
{
    public class AES
    {
        private byte[] key;

        public AES(string key)
        {   
            using (SHA256CryptoServiceProvider sha256 = new SHA256CryptoServiceProvider())
            {
                byte[] keyBytes = Encoding.ASCII.GetBytes(key);
                this.key = sha256.ComputeHash(keyBytes);
            }
        }

        public static AES New(string key)
        {
            return new AES(key);
        }

        public byte[] Encrypt(byte[] plain)
        {
            using (var aes = new AesManaged())
            {
                aes.Key = this.key;
                var encryptor = aes.CreateEncryptor();
                using (var ms = new MemoryStream())
                {
                    using (var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write))
                    {
                        using (var sw = new BinaryWriter(cs))
                        {
                            sw.Write(plain);
                        }
                    }
                    byte[] cipher = ms.ToArray();
                    byte[] msg = new byte[cipher.Length + aes.IV.Length];
                    Buffer.BlockCopy(aes.IV, 0, msg, 0, aes.IV.Length);
                    Buffer.BlockCopy(cipher, 0, msg, aes.IV.Length, cipher.Length);

                    return msg;
                }
            }
        }

        public byte[] Decrypt(byte[] message)
        {
            using (var aes = new AesManaged())
            {
                int cipherLen = message.Length - aes.IV.Length;
                byte[] iv = new byte[aes.IV.Length];
                byte[] cipher = new byte[cipherLen];
                
                Buffer.BlockCopy(message, 0, iv, 0, aes.IV.Length);
                Buffer.BlockCopy(message, aes.IV.Length, cipher, 0, cipherLen);

                aes.Key = this.key;
                aes.IV = iv;

                using (var ms = new MemoryStream(cipher))
                {
                    var decryptor = aes.CreateDecryptor();
                    using (var cs = new CryptoStream(ms, decryptor, CryptoStreamMode.Read))
                    {
                        using (var result = new MemoryStream())
                        {
                            cs.CopyTo(result);
                            return result.ToArray();
                        }
                    }
                }
            }
        }
    }
}

"@

Add-Type -TypeDefinition $source -Language CSharp