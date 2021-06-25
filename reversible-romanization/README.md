# Reversible Romanization

Linux terminals can display a fair share of Unicode characters (if you spend some time with fonts) but arguably, Latin with diacritics is best covered.

To safely work with non-Latin alphabets in terminals, Ondrej prefers to romanize the text in a rather arbitrary but _fully reversible_ way. That's what these tools do. ``devaroman`` is for Devanagari, ``arabroman`` is for Arabic script.

Sample usage:

```
echo "I want to see ताजमहल." | ./devaroman
_I _w_a_n_t _t_o _s_e_e tàjmhl.

echo "I want to see ताजमहल." | ./devaroman | ./devaroman --inv 
I want to see ताजमहल.

echo "I want to see ताजमहल." | ./devaroman --dont-mark-originalss
I want to see tàjmhl.
  # this is obviously not reversible
```

Ondřej Bojar, bojar@ufal.mff.cuni.cz
