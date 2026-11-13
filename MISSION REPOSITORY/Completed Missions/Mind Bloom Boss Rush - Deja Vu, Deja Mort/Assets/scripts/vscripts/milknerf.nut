::MILK_NERF_MULTIPLIER <- 0.5
::CONCH_NERF_MULTIPLIER <- 0.5 //DOES NOT AFFECT CONCH ON ITS OWN. Make sure this matches your conch modifier! Only kicks in for when conch and milk are combined

::milkNerf <- {

	function OnScriptHook_OnTakeDamage(params) {
		if(params.attacker == null) return
		if(params.attacker.GetTeam() != 2) return

		//Only activate for damage done on milked victims
		//Apparently const_entity can be non-player entities which doesnt like InCond()
		if(!(params.const_entity.IsPlayer())) return
		if(!(params.const_entity.InCond(27))) return

		//OnTakeDamage triggers before the attack hits and the game works through the hurty part
		//Save the attacker's health ontakedamage and then get it back on player_hurt so we know how much the attacker healed from milk 
		local scope = params.attacker.GetScriptScope()
		if(!("milkNerfPreviousHealth" in scope)) {
			scope.milkNerfPreviousHealth <- 0
		}

		scope.milkNerfPreviousHealth <- params.attacker.GetHealth()
	}

	function OnGameEvent_player_hurt(params) {
		local attacker = GetPlayerFromUserID(params.attacker)
		if(attacker == null) return
		if(!attacker.IsPlayer()) return
		if(attacker.GetTeam() != 2) return

		//Mad milk syringes do not trigger this when hitting an unmilked target, not an issue
		local victim = GetPlayerFromUserID(params.userid)
		if(!(victim.InCond(27))) return

		local scope = attacker.GetScriptScope()
		//Failsafe. I don't think this is possible to trigger though
		if(!("milkNerfPreviousHealth" in scope)) {
			scope.milkNerfPreviousHealth <- attacker.GetHealth()
		}

		local healthHealedFromMilk = attacker.GetHealth() - scope.milkNerfPreviousHealth

		if(healthHealedFromMilk <= 0) return

		local extraConchHealth = 0

		if(attacker.InCond(29)) {
			extraConchHealth = params.damageamount * 0.35 * CONCH_NERF_MULTIPLIER
		}

		local properHealth = attacker.GetHealth() - healthHealedFromMilk + (params.damageamount * 0.6 * MILK_NERF_MULTIPLIER) + extraConchHealth
		if(properHealth > attacker.GetMaxHealth()) properHealth = attacker.GetMaxHealth()
		attacker.SetHealth(properHealth)
	}

}
__CollectGameEventCallbacks(milkNerf)
