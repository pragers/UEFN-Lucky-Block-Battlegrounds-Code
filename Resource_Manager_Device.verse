
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/FortPlayerUtilities }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Code for the lucky blocks and materials on a specific island
Island := class(creative_device):
    @editable Spawner:player_spawner_device = player_spawner_device{}
    @editable Wood:prop_manipulator_device = prop_manipulator_device{}
    @editable Stone:prop_manipulator_device = prop_manipulator_device{}
    @editable StoneTimer:timer_device = timer_device{}
    @editable Metal:prop_manipulator_device = prop_manipulator_device{}
    @editable MetalTimer:timer_device = timer_device{}
    @editable LuckyBlocks : []LuckyBlock1 = array{}
    @editable ClassSwitch : class_and_team_selector_device = class_and_team_selector_device{}
    @editable LuckyBlockDaily : DailyLuckyBlock = DailyLuckyBlock{}
    @editable ObjectivePulse : objective_device = objective_device{}
    @editable WoodObjectivePulse : objective_device = objective_device{}
    @editable TeleporterObjectivePulse : objective_device = objective_device{}
    @editable Teleporter : teleporter_device = teleporter_device{}

    var Tutorialvar : logic = false
    var MetalTimerOriginalLocation : transform = transform{}
    var StoneTimerOriginalLocation : transform = transform{}
    var Player: ?player = false

    #initialize device on game start
    Init():void=
        Spawner.SpawnedEvent.Subscribe(PlayerSpawned)
        StoneTimer.SuccessEvent.Subscribe(StoneTimerSuccess)
        set StoneTimerOriginalLocation = StoneTimer.GetTransform()
        set MetalTimerOriginalLocation = MetalTimer.GetTransform()
        InitLuckyBlocks(false)
        LuckyBlockDaily.Init(false)
        MetalTimer.SuccessEvent.Subscribe(MetalTimerSuccess)
        Metal.DisableResourceNodeOverrides()
        Stone.DisableResourceNodeOverrides()

    #Starts timers and activates logic when a player spawns
    PlayerSpawned(Agent:agent):void=
        Spawner.Disable()
        ClassSwitch.ChangeClass(Agent)
        if:
            Player = false
            AgentPlayer := player[Agent]
        then:
            if:
                not LastOpened[AgentPlayer]
                set LastOpened[AgentPlayer] = 0.0
            then:
                ObjectivePulse.ActivateObjectivePulse(AgentPlayer)
                for(LuckyBloc:LuckyBlocks):
                    spawn:
                        WaitForOpen(LuckyBloc)
            set Player = option{AgentPlayer}
            InitLuckyBlocks(option{Agent})
            LuckyBlockDaily.Init(option{Agent})
            StoneTimer.Enable()
            MetalTimer.Enable()
            StoneTimer.Start(Agent)
            MetalTimer.Start(Agent)
            if:
                StoneTimer.TeleportTo[StoneTimerOriginalLocation]
                MetalTimer.TeleportTo[MetalTimerOriginalLocation]

    #timer functions for materials
    StoneTimerSuccess(AgentO:?agent):void=
        Stone.SetResourceOverridesActive()
        spawn:
            MoveStoneTimerAway()
    MoveStoneTimerAway()<suspends>:void=
        loop:
            if:
                StoneTimer.TeleportTo[vector3{X := 0.0, Y := 0.0, Z := -10000.0}, MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)]
            then:
                break
    MoveMetalTimerAway()<suspends>:void=
        loop:
            if:
                MetalTimer.TeleportTo[vector3{X := 0.0, Y := 0.0, Z := -10000.0}, MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)]
            then:
                break
    MetalTimerSuccess(AgentO:?agent):void=
        Metal.SetResourceOverridesActive()
        spawn:
            MoveMetalTimerAway()


    #Checks if the leaving player is the one that is currently playing on this island
    #If so, it resets the island
    CheckPlayer(LeavingPlayer:player):void=
        if:
            LeavingPlayer = Player?
        then:
            set Player = false
            Metal.DisableResourceNodeOverrides()
            Stone.DisableResourceNodeOverrides()
            for(LuckyBloc:LuckyBlocks):
                LuckyBloc.Denit()
            LuckyBlockDaily.Denit()
            StoneTimer.Reset()
            MetalTimer.Reset()
            Spawner.Enable()
            set Tutorialvar = false


    #Initializes all lucky blocks on the island
    InitLuckyBlocks(AgentO:?agent):void=
        for(LuckyBlock2:LuckyBlocks):
            LuckyBlock2.Init(AgentO)

    #Waits for the player to open a lucky block for the tutorial
    WaitForOpen(LuckyBloc:LuckyBlock1)<suspends>:void=
        LuckyBloc.OpenedEvent.Await()
        if:
            Player1 := Player?
            Tutorialvar = false
        then:
            ObjectivePulse.DeactivateObjectivePulse(Player1)
            set Tutorialvar = true
            WaitForDamage(Player1)


    #waits for a player to gather materials and enter the teleporter for the tutorial
    WaitForDamage(Agent:agent)<suspends>:void=
        WoodObjectivePulse.ActivateObjectivePulse(Agent)
        Wood.HarvestingEvent.Await()
        WoodObjectivePulse.DeactivateObjectivePulse(Agent)
        TeleporterObjectivePulse.ActivateObjectivePulse(Agent)
        Teleporter.EnterEvent.Await()
        TeleporterObjectivePulse.DeactivateObjectivePulse(Agent)
    


#general game manager
Resource_Manager_Device := class(creative_device):
    @editable Islands : []Island = array{}
    @editable ElimMan : elimination_manager_device = elimination_manager_device{}

    #Initializes all the islands and subscribes to player removed event
    OnBegin<override>()<suspends>:void=
        for(PlayerIsland:Islands):
            PlayerIsland.Init()

        GetPlayspace().PlayerRemovedEvent().Subscribe(PlayerRemoved)

    #Checks which island the leaving player is on and resets the island if the player is on the island
    PlayerRemoved(Player:player):void=
        for(PlayerIsland:Islands):
            PlayerIsland.CheckPlayer(Player)
