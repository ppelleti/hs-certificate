-- |
-- Module      : Data.X509
-- License     : BSD-style
-- Maintainer  : Vincent Hanquez <vincent@snarc.org>
-- Stability   : experimental
-- Portability : unknown
--
-- Read/Write X509 Certificate, CRL and their signed equivalents.
--
-- Follows RFC5280 / RFC6818
--

module Data.X509
    -- * Types
    , Certificate(..)
    , DistinguishedName(..)
    , PubKey(..)
    , module Data.X509.CertificateChain
    , module Data.X509.AlgorithmIdentifier
    , module Data.X509.Ext

    -- * Signed types and marshalling
    , Signed(..)
    , SignedExact
    , getSigned
    , getSignedData
    , objectToSignedExact
    , encodeSignedObject
    , decodeSignedObject

    -- * Hash distinguished names related function
    , hashDN
    , hashDN_old
    ) where

import Data.ASN1.Types
import Data.ASN1.Encoding
import Data.ASN1.BinaryEncoding
import qualified Data.ASN1.BinaryEncoding.Raw as Raw (toByteString)
import Data.ASN1.Stream
import Data.ASN1.BitArray
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as L

import Data.X509.Internal
import Data.X509.Cert hiding (encodeDN)
import qualified  Data.X509.Cert as Cert
import Data.X509.Ext
import Data.X509.CertificateChain
import Data.X509.Signed
import Data.X509.PublicKey
import Data.X509.AlgorithmIdentifier

import qualified Crypto.Hash.MD5 as MD5
import qualified Crypto.Hash.SHA1 as SHA1


-- | Make an openssl style hash of distinguished name
hashDN :: DistinguishedName -> B.ByteString
hashDN = shorten . SHA1.hash . encodeASN1' DER . Cert.encodeDNinner toLowerUTF8
    where toLowerUTF8 (_, s) = (UTF8, B.map asciiToLower s)
          asciiToLower c
            | c >= w8A && c <= w8Z = fromIntegral (fromIntegral c - fromEnum 'A' + fromEnum 'a')
            | otherwise            = c
          w8A = fromIntegral $ fromEnum 'A'
          w8Z = fromIntegral $ fromEnum 'Z'

-- | Create an openssl style old hash of distinguished name
hashDN_old :: DistinguishedName -> B.ByteString
hashDN_old = shorten . MD5.hash . encodeASN1' DER . Cert.encodeDN

shorten :: B.ByteString -> B.ByteString
shorten b = B.pack $ map i [3,2,1,0]
    where i n = B.index b n