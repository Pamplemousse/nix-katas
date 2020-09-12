# nix-katas

Programming exercises done using the [Nix expression language](https://nixos.org/manual/nix/stable/#ch-expression-language).

**Note:** Beware that there is no test framework for Nix, and the assertions do not provide nice outputs.

```shell
nix-instantiate --eval fizzbuzz.nix --arg max 50
nix-instantiate --eval bowling.nix --arg rolls "[ 10 10 10 10 10 10 10 10 10 10 10 10 ]"
```
