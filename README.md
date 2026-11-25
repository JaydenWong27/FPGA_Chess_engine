Things i should add

Quiescence search. At depth 0, keep searching captures only, letting the side to move "stand pat" on the eval. This is the biggest strength gain for your engine.
Movegen needs a captures-only mode (targets & them_bb, plus promotions).
The search FSM needs one more state.
Captures first. Run movegen twice per node, captures then quiet moves. Alpha-beta then cuts off much more, making every depth faster and keeping quiescence cheap.
Incremental eval. Update material and piece-square scores in make_move as each move is made, so a leaf costs a few clocks instead of about 35. That's roughly 5× faster at the leaves.
Time control in the host. host/uci.py searches depth 1, 2, 3… and stops before it would run over a time budget. No RTL changes needed.
Better evaluation. The endgame king table, passed-pawn bonus and bishop pair.
Small fix in measure_elo.py: add timeout=None when opening your engine. Without it, depth-5 matches can crash on slow moves.
