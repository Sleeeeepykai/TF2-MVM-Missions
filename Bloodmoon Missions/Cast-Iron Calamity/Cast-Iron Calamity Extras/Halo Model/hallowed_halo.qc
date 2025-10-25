// Created by Crowbar 0.71

$modelname "cast_iron_calamity/hallowed_halo.mdl"

$bodygroup "body"
{
	studio "hallowed_halo.smd"
}


$surfaceprop "metal"

$contents "solid"

$cdmaterials "models/cast_iron_calamity"
$cdmaterials ""

$cbox 0 0 0 0 0 0

$definebone "bip_head" "" 0.000000 0.000000 0.000000 -0.000000 0.000000 89.999985 0.000000 0.000000 0.000000 -0.000000 0.000000 0.000000

$sequence "ref" {
	"ref.smd"
	fadein 0.2
	fadeout 0.2
	fps 30
}