# ufal-tools

These are assorted shell tools for natural language processing, machine
translation, grid computing.
All of them should be self-contained.

The tools *may* depend on the network environment of UFAL, but whenever possible, they should check for the environment and die if they are run elsewhere.

They also ideally should support AIC or Metacentrum.

Example:

```
./qswrapper gpu-troja.q@tdll2 3 'echo ahoj'
```
