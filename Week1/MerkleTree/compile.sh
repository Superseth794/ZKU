#!/bin/bash

rm -rf MerkleTree_js
rm MerkleTree.r1cs witness.wtns

circom MerkleTree.circom --r1cs --wasm --sym

cd MerkleTree_js

node generate_witness.js MerkleTree.wasm ../input.json witness.wtns

snarkjs powersoftau new bn128 15 pot12_0000.ptau -v

snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v

snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v

snarkjs groth16 setup ../MerkleTree.r1cs pot12_final.ptau merkle2_0000.zkey

snarkjs zkey contribute merkle2_0000.zkey merkle2_0001.zkey --name="1st Contributor Name" -v

snarkjs zkey export verificationkey merkle2_0001.zkey verification_key.json

snarkjs groth16 prove merkle2_0001.zkey witness.wtns proof.json public.json

snarkjs groth16 verify verification_key.json public.json proof.json

snarkjs zkey export solidityverifier merkle2_0001.zkey verifier.sol

cat verifier.sol | pbcopy