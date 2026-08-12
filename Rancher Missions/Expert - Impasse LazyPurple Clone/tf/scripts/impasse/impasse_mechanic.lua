encoreCapable = 1
alreadyTriggered = 0

encoreYes = 0
encoreNo = 0

--Hello there :)

function OnWaveInit(wave)
    for _, player in pairs(ents.GetAllPlayers()) do

        timer.Simple(1, function()
            player:AcceptInput("$PlaySoundToSelf", ")weapons/recon_ping.wav")
        end)
    end

    if wave == 1 or wave == 7 then
        killCycle()
        encoreCapable = 1

    elseif wave == 2 and encoreCapable == 1 then

        for _, player in pairs(ents.GetAllPlayers()) do
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}?//agement : Data received. Intriguing results.")
        end
    elseif wave == 2 and encoreCapable == 0 then
        
        for _, player in pairs(ents.GetAllPlayers()) do
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}?//agement : Data received... Results are unsatisfactory.")
        end
    elseif wave == 3 then
        for _, player in pairs(ents.GetAllPlayers()) do
            player:AcceptInput("$DisplayTextChat", "{Green}---RE-ESTABLISHING CONNECTION---")
            timer.Simple(5, function()
                player:AcceptInput("$DisplayTextChat", "{Green}Mana-Management : ---Tea- Fortress?>> Can you copy-")
            end)
            timer.Simple(9, function()
                player:AcceptInput("$DisplayTextChat", "{Green}---RE-ESTABLISHING CONNECTION---")
            end)
            timer.Simple(15, function()
                player:AcceptInput("$DisplayTextChat", "{Green}Management : This unknown frequency is interfering with our connection!")
            end)
            timer.Simple(20, function()
                timer.Create(0.2, function()
                player:AcceptInput("$DisplayTextChat", "{Green}Management : DO NOT UNDERESTIMATE-")
                end, 3)

            end)
            timer.Simple(21, function()
                player:AcceptInput("$DisplayTextChat", "{RED}---RE-ESTABLISHING CONNECTION---")
            end)
            timer.Simple(22, function()
                timer.Create(0.5, function()
                    player:AcceptInput("$DisplayTextChat", "{RED}---CONNECTION TERMINATION IMMINENT---")
                end, 10)
            end)
            timer.Simple(28.2, function()
                for _, player in pairs(ents.GetAllPlayers()) do    
                    timer.Create(-1, function()
                        player:AcceptInput("$DisplayTextChat", " ")
                    end, 7)
                end
            end)
            timer.Simple(29.5, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}Do not interfere with my research.")
            end)
        end
    elseif wave == 4 and encoreCapable == 1 then
        for _, player in pairs(ents.GetAllPlayers()) do
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}///@gement : Data is satisfactory, yet again. Experimentation continues.")
            timer.Simple(5, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}///@gement : Configurating variables...")
            end)
            timer.Simple(10, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}///@gement : Enhancing combat capabilities...")
            end)
            timer.Simple(15, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}///@gement : Modifying [UNSTOPPABLE FORCES]...")
            end)
            timer.Simple(20, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}///@gement : ...And yet the power you hold grants you a fighting chance... Show me more.")
            end)
        end
    elseif wave == 4 and encoreCapable == 0 then
        for _, player in pairs(ents.GetAllPlayers()) do
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}///@gement : Data is fairly satisfactory, yet again. Experimentation continues.")
            timer.Simple(5, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}///@gement : Configurating variables...")
            end)
            timer.Simple(10, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}///@gement : Enhancing combat capabilities...")
            end)
            timer.Simple(15, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}///@gement : Modifying [UNSTOPPABLE FORCES]...")
            end)
        end
    elseif wave == 5 and encoreCapable == 1  then
        for _, player in pairs(ents.GetAllPlayers()) do
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}M@n@geMENT : Dear High Priority Targets. Your Data Experiment Result has brought immense satisfaction beyond. This time, there will be no cohesion.")
            timer.Simple(5, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}M@n@geMENT : You are not to win this time. If you beat the odds, we plan to intervene. You will prove yourself to us...")
            end)
            timer.Simple(10, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}M@n@geMENT : If so. Please prepare youselves to be detained to the end of time.")
            end)
            timer.Simple(15, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}T i m e . . .")
            end)
            timer.Simple(20, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}T  i  m  e  .")
            end)
        end
    elseif wave == 5 and encoreCapable == 0  then
        for _, player in pairs(ents.GetAllPlayers()) do
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}M@n@gement : Dear Mercenaries. Your Data Experiment Result has brought in... fairly acceptable results. This time, there will be no cohesion.")
            timer.Simple(5, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}M@n@gement : You are not to win this time. We will not meet again.")
            end)
            timer.Simple(10, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}M@n@gement : For you do not meet satisfactory requirements for our effort and time.")
            end)
            timer.Simple(15, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}T i m e . . .")
            end)
            timer.Simple(20, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}T  i  m  e  .")
            end)
        end
    elseif wave == 6  then

        if encoreCapable == 1 then
            for _, player in pairs(ents.GetAllPlayers()) do
                timer.Simple(1, function()
                    player:AcceptInput("$DisplayTextChat", "{8ff347}T-Team Fortress? Thank God I finally got in contact again!")
                end)
                timer.Simple(6, function()
                    player:AcceptInput("$DisplayTextChat", "{8ff347}It seems that this otherworldly force is about to launch an all-out attack on us.")
                end)
                timer.Simple(11, function()
                    player:AcceptInput("$DisplayTextChat", "{8ff347}So put in your all in this final fight! Because theres no going back.")
                end)
                timer.Simple(16, function()
                    player:AcceptInput("$DisplayTextChat", "{8ff347}Good luck, Team Fortress.")
                end)
                timer.Simple(21, function()
                    player:AcceptInput("$DisplayTextChat", "{GREEN}MVM MECHANIC CHANGE NOTICE : BOTS NO LONGER PICK RANDOM ROUTES WHEN THE ALARM SETS OFF!")
                end)
            end
        end
    end

    
end

function OnWaveStart(wave)
    retconfixupshenanigans = 0
end
--
function OnWaveSpawnTank(tank, wave)
    for _, player in pairs(ents.GetAllPlayers()) do
        if tank.m_iMaxHealth == 13000 then
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}Manage : Unstoppable {red}INVINCIBLE {FFC0CB}Force Materialized. {blue}" .. tank.m_iHealth.. " {fbeccb}Damage Requirement.")
            timer.Simple(3, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}Management : Destroy{red} The Maintainer With A {BLUE}BOSS HEALTH BAR. {red}To Invalidate Invincibility")
            end)
        elseif tank:GetName() ~= "combattank|minigun|fireball" then
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}Manage : Unstoppable Force Materialized. {blue}" .. tank.m_iHealth.. " {fbeccb}Damage Requirement.")
        else
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}Manage : Unstoppable {RED}WAR MACHINE {FFC0CB}Materialized. {blue}" .. tank.m_iHealth.. " {fbeccb}Damage Requirement.")
        end
    end
end
--
--
function OnWaveFail(wave)
    encoreYes = 0
    encoreNo = 0

	if wave ~= 1 and wave ~= 7 then
		failedCondition()
	end

    for _, player in pairs(ents.GetAllPlayers()) do
        if player:IsRealPlayer() then
            player.hasVoted = 0
        end
    end
end

--END OF DIALOUGES

--////////////////////////////// SOLDIER COMMANDER ABILITY ////////////////////////////////////

function bombThem(_, activator)
    local mapInfo = {
        translation = "0 0 0"
    }
    for _, player in pairs(ents.FindInSphere(activator:GetAbsOrigin(), 800, "player")) do

        if player:IsRealPlayer() and player:IsAlive() and player.m_iTeamNum == 2 and not player:InCond(6) then
            local playerInfo = {
                        translation = player:GetAbsOrigin()
                    }
            ents.SpawnTemplate("CommanderAirstrikePT", playerInfo)
        end
    end
end
--//
function bombThemVoid(_, activator)
    local mapInfo = {
        translation = "0 0 0"
    }
    for _, player in pairs(ents.FindInSphere(activator:GetAbsOrigin(), 800, "player")) do

        if player:IsRealPlayer() and player:IsAlive() and player.m_iTeamNum == 2 and not player:InCond(6) then
            local playerInfo = {
                        translation = player:GetAbsOrigin()
                    }
            ents.SpawnTemplate("VoidOpportunistAirstrikePT", playerInfo)
        end
    end
end
--///

--// The Voting at the end of wave 5... are you worthy?

novoteEnding = 1
EncoreMenu = {
    timeout = 0, 
    title = "The Void has seen your potential. Care for an Encore?",
    itemsPerPage = 2,
    flags = MENUFLAG_NO_SOUND,
    onSelect = function(voter, index)
        if index == 1 and voter.hasVoted ~= 1 then

            encoreNo = encoreNo + 1
            novoteEnding = 0

            voter.hasVoted = 1
            voter:PlaySoundToSelf('ui/hint.wav')
        elseif index == 2 and voter.hasVoted ~= 1 then

            encoreYes = encoreYes + 1
            novoteEnding = 0

            voter.hasVoted = 1
            voter:PlaySoundToSelf('ui/hint.wav')
        end
    end
}

HeresTheThing = {
	timeout = 5,
	title = 'Challenge : Dont let the bots deploy the bomb!',
	flags = MENUFLAG_NO_SOUND,
	[1] = {text=''},
}

ResultMenu = {
	timeout = 5,
	title = 'You Have Made Your Choice...',
	flags = MENUFLAG_NO_SOUND,
	[1] = {text=''},
}

NoTieMenu = {
	timeout = 5,
	title = 'We deem you high priority. We will engage.',
	flags = MENUFLAG_NO_SOUND,
	[1] = {text=''},
}

NoVoteMenu = {
	timeout = 5,
	title = 'Indecisive. Rather Unfortunate...',
	flags = MENUFLAG_NO_SOUND,
	[1] = {text=''},
}

function VoteForEncore()

    local encore = timer.Create(0.22, function()
        EncoreMenu[1] = {text = "Deny. Live To See Another Day. " ..encoreNo.."/6"}
        EncoreMenu[2] = {text = "Accept. One Last Time (Encore Mode) "..encoreYes.."/6"}

        for _, player in pairs(ents.GetAllPlayers()) do
            if player:IsRealPlayer() and player.m_iTeamNum == 2 then
                player:DisplayMenu(EncoreMenu)
    
            end
        end
    end, 0)

    timer.Simple(20, function()

        for _, player in pairs(ents.GetAllPlayers()) do
            if player:IsRealPlayer() and player.m_iTeamNum == 2 then
                player:PlaySoundToSelf('ui/hint.wav')
                player:AcceptInput("$DisplayTextChat", "{RED} 10 Seconds Remain.")
            end
        end
    end)

    timer.Simple(30, function()
        timer.Stop(encore)

        for _, player in pairs(ents.GetAllPlayers()) do
            if player:IsRealPlayer() and player.m_iTeamNum == 2 then

                player:DisplayMenu(ResultMenu)
                player:PlaySoundToSelf('ui/hint.wav')
            end
        end

        timer.Simple(3, function()

            if encoreYes < encoreNo then
				-- Fix W5 completion tracking.
				FireEvent("mvm_wave_complete", {
					advanced = true
				})
                ents.FindByName("point_populator_interface"):AcceptInput("$JumpToWave", 7)
            elseif encoreYes > encoreNo then

                ents.FindByName("EncoreTransitionRelay"):AcceptInput("Trigger")

                timer.Simple(9, function()
                    ents.FindByName("point_populator_interface"):AcceptInput("$FinishWave")
                end)
            elseif encoreYes == encoreNo and novoteEnding == 0 then 

                for _, player in pairs(ents.GetAllPlayers()) do
                    if player:IsRealPlayer() and player.m_iTeamNum == 2 then
        
                        player:DisplayMenu(NoTieMenu)
                        player:PlaySoundToSelf('ui/hint.wav')
                    end

                    timer.Simple(4, function()
                        ents.FindByName("EncoreTransitionRelay"):AcceptInput("Trigger")

                        timer.Simple(9, function()
							-- Fix W5 completion tracking.
							FireEvent("mvm_wave_complete", {
								advanced = true
							})
                            ents.FindByName("point_populator_interface"):AcceptInput("$JumpToWave", 7)
                        end)
                    end)
                end
            elseif novoteEnding == 1 then

                for _, player in pairs(ents.GetAllPlayers()) do
                    if player:IsRealPlayer() and player.m_iTeamNum == 2 then
        
                        player:DisplayMenu(NoVoteMenu)
                        player:PlaySoundToSelf('ui/hint.wav')
                    end
                    timer.Simple(1.22, function()
						-- Fix W5 completion tracking.
						FireEvent("mvm_wave_complete", {
							advanced = true
						})
                        ents.FindByName("point_populator_interface"):AcceptInput("$JumpToWave", 7)
                    end)
                end
            end
        end)
    end)
end

function failedCondition()

    if encoreCapable == 1 then
        encoreCapable = 0 
    end
end

function setUpEncoreRequirements()
    if encoreCapable == 1 then
        for _, player in pairs(ents.GetAllPlayers()) do

            timer.Simple(5, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}?//agement : These specimen... Have potential.")
            end)
            timer.Simple(10, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}?//agement : Sending Assignment...")
            end)
            timer.Simple(15, function()
                player:AcceptInput("$DisplayTextChat", "{FFC0CB}?//agement : Optional Assignment: {red}DO NOT LOSE ONCE. {FFC0CB}If achieved, you will be eligible for further experimentation.")
                player:DisplayMenu(HeresTheThing)
            end)
        end
    end

    if encoreCapable ~= 0 then

        encoreValid = timer.Create(0.22, function()
            
            if encoreCapable == 0 and alreadyTriggered ~= 1 then
                for _, player in pairs(ents.GetAllPlayers()) do

                    if player:IsRealPlayer() then
                    player:AcceptInput("$DisplayTextChat", "{FFC0CB} Potential Highest Priority Targets... {RED} INVALIDATED. {FFC0CB}You are not capable.")
                    end
                end
                timer.Stop(encoreValid)
                alreadyTriggered = 1
            end
        end, 0)
    end
end

function encoreCheck()
    if encoreCapable == 0 then

        ents.FindByName("EncoreFailRelay"):AcceptInput("Trigger")

        for _, player in pairs(ents.GetAllPlayers()) do
            player:AcceptInput("$DisplayTextChat", "{FFC0CB}Management : Your results have been recorded... Do Better Next Time.")
        end

        timer.Simple(5,function()        
            ents.FindByName("point_populator_interface"):AcceptInput("$FinishWave")

            timer.Simple(-1, function()
                ents.FindByName("point_populator_interface"):AcceptInput("$FinishWave")
            end)
        end)
    end
end


------------------------------------------------------------

function HoKIcon(_, activator)
    activator.m_iszClassIcon = "heavy_deflector_healonkill"
end
function fistIcon(_, activator)
    activator.m_iszClassIcon = "heavy_fist_nys"
end
function BurstIcon(_, activator)
    activator.m_iszClassIcon = "demo_sticky_daan"
end

waveIndex = 1
alreadyWaved = 0
function encoreWaveCycler()

    if waveIndex < 1 then
        waveIndex = 1
    end

    local cycleLogic = {
        ents.FindByName("EncoreWave1"),
        ents.FindByName("EncoreWave2"),
        ents.FindByName("EncoreWave3"),
        ents.FindByName("EncoreWave4")
    }

    -- print(waveIndex)

    if waveIndex == 1 then
        cycleLogic[1]:AcceptInput("Trigger")
        
    elseif waveIndex == 2 then
        cycleLogic[2]:AcceptInput("Trigger")

    elseif waveIndex == 3 then
        cycleLogic[3]:AcceptInput("Trigger")

    elseif waveIndex == 4 then
        cycleLogic[4]:AcceptInput("Trigger")

    end


    waveIndex = (waveIndex + 1) % 5
    -- util.PrintToChatAll("IncludeScript(`alternatewaves`, getroottable());AlternateWavebars("..waveIndex..")")

    if alreadyWaved ~= 1 then
        -- util.PrintToChatAll("timis")

        donavan = timer.Create(6, function() 
            encoreWaveCycler()
        end, 0)
        alreadyWaved = 1

    end
end

function killCycle()
	if donavan ~= nil then
    	timer.Stop(donavan)
	end
    alreadyWaved = 0
end

function CustomBombDeploy(_, activator)
    local tankCheck = activator
    local bombdeployrelay = ents.FindByName("CombatTankDeployRelay")

    if tankCheck:GetName("combattank|minigun|fireball") then 
        bombdeployrelay:AcceptInput("Trigger")
    end
end

function fixup()
    retconfixupshenanigans = 1
end

function theEndofImpasse()
    for _, player in pairs(ents.GetAllPlayers()) do
        if IsTeamAssignedHuman(player) then
			util.PrintToChatAll("\x07eb2326" .. player:GetPlayerName() .. " \x078ff347LISTED FOR FUTURE INTERESTS.")
        end
    end
end

local insults =
{
    [TF_CLASS_SCOUT] = {
        "Hell yeah, we're doing this!",
        "Got my buckets of chicken for the ride.",
        "Its time to end this robot war, fellas!"
    },
    [TF_CLASS_SOLDIER] = {
        "Men, It's time to kick some real robot ass.",
        "Time to put a boot on that tin-can Gray Mann!",
        "Last one alive lock the door!"
    },
    [TF_CLASS_PYRO] = {
        "hudda hudda hurr!",
        "hudda hudda hurr!",
        "i will fry the drying dying flesh of this pathetic leader of metal to ash."
    },
    [TF_CLASS_DEMOMAN] = {
        "Lads, I'm bringing us drinks for the ride!",
        "Oh I'm gonna beat that old man so hard he'll have a twitch!",
        "eeeeeugh *burp* LETS DO IT!"
    },
    [TF_CLASS_HEAVYWEAPONS] = {
        "Da, we do this.",
        "Big contract pays well, yes? OHOHO!",
        "Big plans for Gray Mann."
    },
    [TF_CLASS_ENGINEER] = {
        "YEEHAW! I'm rattled with good 'ol adrenaline. Time to giddy up!",
        "That Gray Mann fellow has something The Administrator has been dying to obtain, I'm in.",
        "Let's finally put them sons of guns to robot hell!"
    },
    [TF_CLASS_MEDIC] = {
        "Aha! I've been waiting to put a new invention to practical use!",
        "I must learn more about this australium they keep. WHO WILL JOIN ME?",
        "They shall be nothing but scrap after I have my new device utilized! Metal will cower."
    },
    [TF_CLASS_SNIPER] = {
        "ALRIGHT! Lets get that old fool!",
        "Got a good 'ol jar of piss ready for that annoying prick.",
        "Somebody wants somebody dead right? We're on it."
    },
    [TF_CLASS_SPY] = {
        "A person of interest? Finally, I've been dying to draw blood once again.",
        "A good Mann is a dead Mann. We're on it.",
        "Time to wear my pristine tuxedo for this one, The contract will pay for the stains."
    }
}

function IsTeamAssignedHuman(player)
	return player:IsRealPlayer() and player.m_iTeamNum == TEAM_RED and player.m_iClass ~= 0 
end

function itstimefortermination()
    for _, player in pairs(ents.GetAllPlayers()) do
        if IsTeamAssignedHuman(player) then
			util.PrintToChatAll("\x07FF3F3F" .. player:GetPlayerName() .. "\x01 : " .. insults[player.m_iClass][math.random(3)])
        end
    end
end
