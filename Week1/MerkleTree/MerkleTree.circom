pragma circom 2.0.0;

include "../../../../External/circom/mimcsponge.circom";

// Template to compute the merkle root of the given leafs
template MerkleTree (nbInputs) {
    // We need at least 2 inputs
    assert(nbInputs > 1);

    signal input leaves[nbInputs];
    signal output merkleRoot;

    // components used to hash the input leafs
    component hashingInputs[nbInputs];
    // components used to hash each tree level to find the parents
    component hashingLeaves[nbInputs - 1];

    // We start by computing the hash of all input leafs and assigning the results to their corresponding parents' input
    var hashingId = 0;
    var idInHash = 0;
    for (var i = 0; i < nbInputs; i++) {
        // Instantiate the template to compute the hash of a single element
        hashingInputs[i] = MiMCSponge(1, 220, 1);
        
        hashingInputs[i].ins[0] <== leaves[i];
        hashingInputs[i].k <== 0;
        
        // We instantiate the parent's template if needed
        if (idInHash == 0) {
            hashingLeaves[hashingId] = MiMCSponge(2, 220, 1);
            hashingLeaves[hashingId].k <== 0;
        }
        
        hashingLeaves[hashingId].ins[idInHash] <== hashingInputs[i].outs[0];
        
        idInHash++;
        if (idInHash == 2) { // We select the next parent if the current parent already received its both outputs
            idInHash = 0;
            hashingId++;
        }
    }

    hashingId = 0;
    idInHash = 0;
    var outputHash = nbInputs / 2; // We start at the first node of the second layer (from bottom) of the tree
    // We compute successively the hash of each tree node until we reach the root
    for (var i = 0; i < nbInputs - 2; i++) {
        // We instanciate the parent's template if needed
        if (idInHash == 0) {
            hashingLeaves[outputHash] = MiMCSponge(2, 220, 1);
            hashingLeaves[outputHash].k <== 0;
        }

        hashingLeaves[outputHash].ins[idInHash] <== hashingLeaves[i].outs[0];

        idInHash++;
        if (idInHash == 2) { // We select the next parent if the current parent already received its both outputs
            idInHash = 0;
            outputHash++;
        }
    }
    
    // Finnaly we get the root which is the output of the final node's circuit
    merkleRoot <== hashingLeaves[nbInputs - 2].outs[0];
}

component main {public [leaves]} = MerkleTree(8);