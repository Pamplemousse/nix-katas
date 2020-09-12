with import <nixpkgs> { };

{ debug ? true
, rolls
}:

let
  /*
  The magic: Update the score "sheet" as the balls are rolled.

  :param acc: The global game state, as a list of `frame`s.
  :param pins: The number of pins knocked down by this roll.

  Each frame is composed of the following:
    - `bonusScore`: The score that will be added by subsequent rolls (if this frame was a strike or a spare).
    - `score`: The number of pins down after two rolls in the frame.
    - `spareBonus`: Initialised to `1` if the frame is a spare, and will be decremented as the `bonusScore` is updated by subsequent rolls.
    - `strikeBonus`: Initialised to `2` if the frame is a strike, and will be decremented as the `bonusScore` is updated by subsequent rolls.
    - `isCompleted`: Tell if the frame is over (i.e. two rolls have been made, or a strike happened).
  */
  _addNextRoll = acc: pins:
    let
      numberOfFrames = builtins.length acc;
    in
      if numberOfFrames == 0 then
        [ (_createNewFrame pins) ]
      else
        let
          _frames = _applyBonuses acc pins;
        in
          let
            isNewFrame = (lib.lists.last acc).isCompleted;
          in
            if isNewFrame then
              if numberOfFrames == 10 then
                _frames
              else
                _frames ++ [ (_createNewFrame pins) ]
            else
              _updatePreviousFrame _frames pins
            ;

  _applyBonuses = frames: pins:
    let
      lastFrame = lib.lists.last frames;
      shorterFrames = _dropLast frames;
    in let
      updatedLastFrame = _updateFrameBonus lastFrame pins;
    in
      if builtins.length shorterFrames == 0 then
        shorterFrames ++ [ updatedLastFrame ]
      else
        let
          secondLastFrame = lib.lists.last shorterFrames;
          shorterShorterFrames = _dropLast shorterFrames;
        in let
          updatedSecondLastFrame = _updateFrameBonus secondLastFrame pins;
        in
          shorterShorterFrames ++ [ updatedSecondLastFrame updatedLastFrame ]
      ;

  _createNewFrame = pins:
    let
      isStrike = pins == 10;
    in let
      bonusScore = 0;
      isCompleted = isStrike;
      score = pins;
      strikeBonus = if isStrike then 2 else 0;
      spareBonus = 0;
    in
      { inherit bonusScore score spareBonus strikeBonus isCompleted; };

  _decrementUnless0 = n:
    assert n >= 0;
    if n == 0 then 0 else n - 1;

  _dropLast = with lib.lists; l: sublist 0 (length l - 1) l;

  _updateFrame = frame: pins:
    let
      isCompleted = true;
      score = frame.score + pins;
    in let
      spareBonus = if score == 10 then 1 else 0;
    in
      with frame; { inherit bonusScore score strikeBonus spareBonus isCompleted; };

  _updateFrameBonus = frame: pins:
    let
      bonusValue = bonus: pins: if bonus > 0 then pins else 0;
    in let
      bonusScore = frame.bonusScore + (bonusValue frame.spareBonus pins) + (bonusValue frame.strikeBonus pins);
      spareBonus = _decrementUnless0 frame.spareBonus;
      strikeBonus = _decrementUnless0 frame.strikeBonus;
    in
      with frame; { inherit bonusScore score strikeBonus spareBonus isCompleted; };

  _updatePreviousFrame = frames: pins:
    let
      lastFrame = lib.lists.last frames;
    in let
      updatedFrame = _updateFrame lastFrame pins;
    in
      (_dropLast frames) ++ [ updatedFrame ];

  _sum = l: builtins.foldl' (acc: x: acc + x) 0 l;

  computeScoreFrom = rolls:
    let
      # The game state is a list of frames.
      initialGameState = [];
      game = builtins.foldl' _addNextRoll initialGameState rolls;
    in _sum (map (frame: frame.score + frame.bonusScore) game);
in
  let tests = f: args:
    assert _decrementUnless0 10 == 9;
    assert _decrementUnless0 1 == 0;
    assert _decrementUnless0 0 == 0;

    assert _dropLast [ 1 2 ] == [ 1 ];
    assert _dropLast [ 1 ] == [ ];
    assert _dropLast [ 0 ] == [ ];

    assert
      _updateFrame { bonusScore = 0; score = 0; spareBonus = 0; strikeBonus = 0; isCompleted = false; } 2
      ==
      { bonusScore = 0; score = 2; spareBonus = 0; strikeBonus = 0; isCompleted = true; };
    assert
      _updateFrame { bonusScore = 0; score = 8; spareBonus = 0; strikeBonus = 0; isCompleted = false; } 2
      ==
      { bonusScore = 0; score = 10; spareBonus = 1; strikeBonus = 0; isCompleted = true; };

    # Note that`_updateFrameBonus` is tested through `_applyBonuses`
    assert
      _applyBonuses [ { bonusScore = 0; score = 10; spareBonus = 1; strikeBonus = 0; isCompleted = true; } ] 2
      ==
      [ { bonusScore = 2; score = 10; spareBonus = 0; strikeBonus = 0; isCompleted = true; } ];
    assert
      _applyBonuses [ { bonusScore = 0; score = 10; spareBonus = 0; strikeBonus = 2; isCompleted = true; } ] 2
      ==
      [ { bonusScore = 2; score = 10; spareBonus = 0; strikeBonus = 1; isCompleted = true; } ];
    assert
      _applyBonuses [ { bonusScore = 2; score = 10; spareBonus = 0; strikeBonus = 1; isCompleted = true; } ] 2
      ==
      [ { bonusScore = 4; score = 10; spareBonus = 0; strikeBonus = 0; isCompleted = true; } ];
    assert
      _applyBonuses [ { bonusScore = 2; score = 10; spareBonus = 0; strikeBonus = 1; isCompleted = true; }
                      { bonusScore = 0; score = 10; spareBonus = 1; strikeBonus = 0; isCompleted = true; }
                    ] 2
      ==
      [ { bonusScore = 4; score = 10; spareBonus = 0; strikeBonus = 0; isCompleted = true; }
        { bonusScore = 2; score = 10; spareBonus = 0; strikeBonus = 0; isCompleted = true; }
      ];

    assert _sum [ 1 2 3 ] == 6;
    assert _sum [] == 0;

    # "Classic" counting
    assert computeScoreFrom [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ] == 0;
    assert computeScoreFrom [ 6 2 8 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ] == 17;
    # Spare bonus
    assert computeScoreFrom [ 2 8 2 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ] == 22;
    assert computeScoreFrom [ 2 8 2 6 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 ] == 52;
    assert computeScoreFrom [ 2 8 8 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 ] == 62;
    # Strike bonus
    assert computeScoreFrom [ 10 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ] == 26;
    assert computeScoreFrom [ 10 10 10 6 2 0 0 0 0 0 0 0 0 0 0 0 0 ] == 82;
    assert computeScoreFrom [ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 10 10 10 ] == 30;
    assert computeScoreFrom [ 10 10 10 10 10 10 10 10 10 10 10 10 ] == 300;

    f args;

  run = { debug, function, argument}:
    if debug then tests function argument else function argument;
in
  run { inherit debug; function = computeScoreFrom; argument = rolls; }
