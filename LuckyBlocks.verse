
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/Devices/CreativeAnimation/InterpolationTypes }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Regular lucky block, timer resets when player rejoins.
LuckyBlock1:= class(creative_device):
    @editable LuckyBlockItemSpawner : item_spawner_device = item_spawner_device{}
    @editable LuckyBlockProp : creative_prop = creative_prop{}
    @editable LuckyBlockButton : button_device = button_device{}
    @editable LuckyBlockTimer : timer_device = timer_device{}
    @editable UnlockTimer : ?timer_device = false
    OpenedEvent : event() = event(){}
    var MaybeCoolDown<private> : logic = false
    var Unlocked<private> : logic = false
    var InitialPosition<private>: transform = transform{}
    var InitialPosition1<private>: transform = transform{}
    var subscriptions<private> : []cancelable = array{}
    var _HasBeenInitialized<private> : logic = false

    # Initializes the lucky block device
    # 'Agent' is the player on the island
    Init(Agent:?agent):void=
        if:
            _HasBeenInitialized = false
        then:
            set InitialPosition = LuckyBlockTimer.GetTransform()
            if:
                Timer := UnlockTimer?
            then:
                set InitialPosition1 = Timer.GetTransform()
            set _HasBeenInitialized = true
        for(I:subscriptions):
            I.Cancel()
        set subscriptions+= array:
            LuckyBlockButton.InteractedWithEvent.Subscribe(_LuckyBlockButtonPressed)
            LuckyBlockTimer.SuccessEvent.Subscribe(_LuckyBlockTimerSuccess)
        if:
            not UnlockTimer?
        then:
            set Unlocked = true
            LuckyBlockButton.Enable()
        else:
            if:
                UnlockTimer1 := UnlockTimer?
            then:
                set subscriptions += array{UnlockTimer1.SuccessEvent.Subscribe(_Unlock)}
                if:
                    UnlockTimer1.TeleportTo[InitialPosition1]
                if:
                    Agent1:=Agent?
                then:
                    LuckyBlockTimer.Enable()
                    UnlockTimer1.Enable()
                    UnlockTimer1.Start()
                    LuckyBlockButton.Disable()
        
        if(LuckyBlockTimer.TeleportTo[vector3{X := 0.0, Y := 0.0, Z := -10000.0}, MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)]){}
        if:
            PropAnimController := LuckyBlockProp.GetAnimationController[]
        then:
            set subscriptions += array{PropAnimController.MovementCompleteEvent.Subscribe(_GrantItem)}


    _LuckyBlockButtonPressed<private>(Agent:agent):void=
        if:
            not MaybeCoolDown = true
            Unlocked = true
        then:
            _LuckyBlockOpened()
            if:
                PropAnimController := LuckyBlockProp.GetAnimationController[]
            then:
                var AnimationKeyFrames : []keyframe_delta = array{}
                RandomFrameCount : int = 6
                InitialRotation := LuckyBlockProp.GetTransform().Rotation
                var CurrentRotation : rotation = InitialRotation
                for(I := 0..RandomFrameCount-1):
                    Interpolation : cubic_bezier_parameters = if(I=0)
                    then EaseIn
                    else Linear

                    RandomFloat1:= GetRandomFloat(-90.0,90.0)
                    RandomFloat2:= GetRandomFloat(-90.0,90.0)
                    RandomFloat3:= GetRandomFloat(-90.0,90.0)
                    RandomRotation:= MakeRotationFromYawPitchRollDegrees(RandomFloat1,RandomFloat2,RandomFloat3)
                    set CurrentRotation = RandomRotation.RotateBy(CurrentRotation)
                    RandomRotationKeyFrame : keyframe_delta = keyframe_delta:
                        DeltaLocation := vector3{X:=0.0,Y:=0.0,Z:=0.0}
                        DeltaRotation := RandomRotation
                        DeltaScale := vector3{X:=1.0,Y:=1.0,Z:=1.0}
                        Time:= 0.2
                        Interpolation := Interpolation
                    set AnimationKeyFrames += array{RandomRotationKeyFrame}

                DefaultRotationKeyFrame : keyframe_delta = keyframe_delta:
                    DeltaLocation := vector3{X:=0.0,Y:=0.0,Z:=0.0}
                    DeltaRotation := MakeShortestRotationBetween(CurrentRotation,InitialRotation)
                    DeltaScale := vector3{X:=1.0,Y:=1.0,Z:=1.0}
                    Time:= 0.5
                    Interpolation := EaseOut

                set AnimationKeyFrames += array{DefaultRotationKeyFrame}

                PropAnimController.SetAnimation(AnimationKeyFrames, ?Mode := animation_mode.OneShot)
                PropAnimController.Play()

    _LuckyBlockOpened<private>():void=
        OpenedEvent.Signal()
        set MaybeCoolDown = true
        LuckyBlockTimer.Enable()
        LuckyBlockTimer.Reset()
        LuckyBlockTimer.Start()
        LuckyBlockButton.Disable()

    _LuckyBlockTimerSuccess<private>(AgentO:?agent):void=
        set MaybeCoolDown = false
        LuckyBlockButton.Enable()
        if(LuckyBlockTimer.TeleportTo[vector3{X := 0.0, Y := 0.0, Z := -10000.0}, MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)]){}


    _GrantItem<private>():void=
        LuckyBlockItemSpawner.SpawnItem()
        if(LuckyBlockTimer.TeleportTo[InitialPosition]){}


    _Unlock<private>(AgentO:?agent):void=
        set Unlocked = true
        if:
            Timer:= UnlockTimer?
            Timer.TeleportTo[vector3{X := 0.0, Y := 0.0, Z := -10000.0}, MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)]
        LuckyBlockButton.Enable()

    #Resets the device
    Denit():void=
        if:
            _HasBeenInitialized = true
        then:
            for(I:subscriptions):
                I.Cancel()
            LuckyBlockTimer.Reset()
            LuckyBlockTimer.Disable()
            if:
                Timer:= UnlockTimer?
            then:
                Timer.Reset()
                Timer.Disable()
                if(Timer.TeleportTo[InitialPosition1]){}
            LuckyBlockButton.Disable()
            if:
                LuckyBlockTimer.TeleportTo[vector3{X := 0.0, Y := 0.0, Z := -10000.0}, MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)]
        else:
            return

# Variable to store last time a player opened the daily lucky block
var LastOpened : weak_map(player,float) = map{}


# Class for a lucky block that can be opened once a day
DailyLuckyBlock:= class(creative_device):
    @editable LuckyBlockItemSpawner : item_spawner_device = item_spawner_device{}
    @editable LuckyBlockProp : creative_prop = creative_prop{}
    @editable LuckyBlockButton : button_device = button_device{}
    @editable LuckyBlockTimer : custom_timer = custom_timer{}
    var subscriptions<private> : []cancelable = array{}
    var CustomSubscription : custom_cancelable = custom_cancelable{}
    var _HasBeenInitialized<private> : logic = false

    # Initializes the lucky block device
    # 'Agent' is the player on the island
    Init(Agent:?agent):void=
        for(I:subscriptions):
            I.Cancel()
        CustomSubscription.Cancel()
        set subscriptions+= array:
            LuckyBlockButton.InteractedWithEvent.Subscribe(_LuckyBlockButtonPressed)
        set CustomSubscription = LuckyBlockTimer.CompletedEvent.Subscribe(_LuckyBlockTimerSuccess)
        LuckyBlockButton.Disable()
        if:
            Agent1:=Agent?
        then:

            Time:= GetSecondsSinceOpened(Agent1)
            if:
                Time >= 60.0*60.0*24.0
            then:
                LuckyBlockButton.Enable()
                if:
                    PropAnimController := LuckyBlockProp.GetAnimationController[]
                then:
                    set subscriptions += array{PropAnimController.MovementCompleteEvent.Subscribe(_GrantItem)}
            else:
                LuckyBlockTimer.SetTime(60.0*60.0*24.0-(GetSecondsSinceOpened(Agent1)))
                LuckyBlockTimer.Start(Agent1,true)
                LuckyBlockButton.Disable()
        else:
            LuckyBlockTimer.Text.HideText()
    
    
    #Returns the time in seconds since the lucky block was last opened by 'Agent'
    #returns 0 if it has never been opened by 'Agent'
    GetSecondsSinceOpened(Agent:agent):float=
        if:
            Time:= LastOpened[player[Agent]]
        then:
            return GetSecondsSinceEpoch() - Time
        else:
            if:
                set LastOpened[player[Agent]] = 0.0
            if:
                Time:= LastOpened[player[Agent]]
            then:
                return GetSecondsSinceEpoch() - Time
            else:
                return 0.0

    
    _LuckyBlockTimerSuccess<private>(AgentO:?agent):void=
        if:
            Agent := AgentO?
        then:
            Time:=GetSecondsSinceOpened(Agent)
            if:
                Time >= 60.0*60.0*24.0
            then:
                LuckyBlockButton.Enable()
    
    
    _LuckyBlockButtonPressed<private>(Agent:agent):void=
        _LuckyBlockOpened(Agent)
        if:
            PropAnimController := LuckyBlockProp.GetAnimationController[]
        then:
            var AnimationKeyFrames : []keyframe_delta = array{}
            RandomFrameCount : int = 8
            InitialRotation := LuckyBlockProp.GetTransform().Rotation
            var CurrentRotation : rotation = InitialRotation
            for(I := 0..RandomFrameCount-1):
                Interpolation : cubic_bezier_parameters = if(I=0)
                then EaseIn
                else Linear

                RandomFloat1:= GetRandomFloat(-90.0,90.0)
                RandomFloat2:= GetRandomFloat(-90.0,90.0)
                RandomFloat3:= GetRandomFloat(-90.0,90.0)
                RandomRotation:= MakeRotationFromYawPitchRollDegrees(RandomFloat1,RandomFloat2,RandomFloat3)
                set CurrentRotation = RandomRotation.RotateBy(CurrentRotation)
                RandomRotationKeyFrame : keyframe_delta = keyframe_delta:
                    DeltaLocation := vector3{X:=0.0,Y:=0.0,Z:=0.0}
                    DeltaRotation := RandomRotation
                    DeltaScale := vector3{X:=1.0,Y:=1.0,Z:=1.0}
                    Time:= 0.2
                    Interpolation := Interpolation
                set AnimationKeyFrames += array{RandomRotationKeyFrame}

            DefaultRotationKeyFrame : keyframe_delta = keyframe_delta:
                DeltaLocation := vector3{X:=0.0,Y:=0.0,Z:=0.0}
                DeltaRotation := MakeShortestRotationBetween(CurrentRotation,InitialRotation)
                DeltaScale := vector3{X:=1.0,Y:=1.0,Z:=1.0}
                Time:= 0.5
                Interpolation := EaseOut

            set AnimationKeyFrames += array{DefaultRotationKeyFrame}

            PropAnimController.SetAnimation(AnimationKeyFrames, ?Mode := animation_mode.OneShot)
            PropAnimController.Play()

    
    _LuckyBlockOpened<private>(Agent:agent):void=
        if:
            set LastOpened[player[Agent]] = GetSecondsSinceEpoch()
        LuckyBlockTimer.SetTime(60.0*60.0*24.0-(GetSecondsSinceOpened(Agent)))
        LuckyBlockTimer.Start(Agent,false) 
        LuckyBlockButton.Disable()

    
    _GrantItem<private>():void=
        LuckyBlockTimer.ShowText()
        LuckyBlockItemSpawner.SpawnItem()
    
    # Reset device
    Denit():void=
        if:
            _HasBeenInitialized = true
        then:
            for(I:subscriptions):
                I.Cancel()
            LuckyBlockTimer.Stop()
            LuckyBlockTimer.Reset()
            LuckyBlockButton.Disable()

        else:
            return
        
