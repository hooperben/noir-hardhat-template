// Our example ZK circuit - a simple ciruit that takes 2 inputs, x and y
// these x and y variables must sum to 15, and x and y must be different
// if these conditions are met - a proof is generated that can later be verified
fn main(x : Field, y : pub Field) {
    assert(x != y);
    assert(x + y == 15);
}