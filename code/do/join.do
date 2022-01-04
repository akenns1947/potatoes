clear all
set more off

cd "~/Documents/grad_school/RA/Potato/PotatoStateSize/Replication_Austin/code/"

capture log close
set logtype text
log using potato_austin.txt, replace

/*This file links the output from ArcMap to the potato data for the Russian Empire*/

/*Only run if not already installed*/
*ssc install matchit
*ssc install freqindex
*ssc install dtalink
*ssc install reclink

/*Import arcmap data*/
import delimited "../temporary/provinces_centroids.txt"

/*Remove 'region' 'governate' 'district' for easier matching*/

replace prov_eng = subinstr(prov_eng, " governorate", "", .)
replace prov_eng = subinstr(prov_eng, " region", "", .)
replace prov_eng = subinstr(prov_eng, " district", "", .)

// /*Manually rename remaining provinces that don't match*/
replace prov_eng = subinstr(prov_eng, "Don Cossack host lands", "Donskoe Voysko", .)
replace prov_eng = subinstr(prov_eng, "Estonia", "Estlyandskaya", .)
replace prov_eng = subinstr(prov_eng, "Grodno", "Grodnenskayaafter1843", .)
replace prov_eng = subinstr(prov_eng, "Kovno", "kovenskaya", .)
// /*Note that there are two 'Livonia governorate' provinces in the output from ArcMap*/
replace prov_eng = subinstr(prov_eng, "Livonia", "Liflyandskaya", .)
replace prov_eng = subinstr(prov_eng, "Minsk", "Minskayafter1843", .)
replace prov_eng = subinstr(prov_eng, "Moscow", "Moscovskaya", .)
replace prov_eng = subinstr(prov_eng, "Orel", "Orlov", .)
replace prov_eng = subinstr(prov_eng, "Simbirsk", "Simbirafter1851", .)
replace prov_eng = subinstr(prov_eng, "Taurida", "Tavricheskayaafter1820", .)
replace prov_eng = subinstr(prov_eng, "Vilna", "Vilenskayafdter1843", .)
replace prov_eng = subinstr(prov_eng, "Viatka", "Vyatskaya", .)

duplicates drop prov_eng, force

save "../temporary/centroids_cleaned.dta", replace

clear all

use "../input/potatoes_russia_empire_19c.dta"

gen prov_short = province

/*Dropping 'skaya' significantly helps with fuzzy matching since it is so prevelant*/
replace prov_short = subinstr(prov_short, "skaya", "", .)

save "../temporary/potatoes.dta", replace

/*Fuzzy matching since some of the names don't exactly match*/
matchit id prov_short using "../temporary/centroids_cleaned.dta", idusing(fid) txtusing(prov_eng) threshold(.52) override

/*Pick the best match based on score*/
gen negative = -(similscore)

sort negative

duplicates drop prov_short, force

sort prov_short

// drop if prov_eng == "Primorskaya"
//
// drop if prov_eng == "Pskovskaya" && province != "Pskovskaya"

/*This data now only has 'prov_eng' and 'prov_short' from each dataset. Used as a bridge between datasets*/
save "../temporary/match.dta", replace

clear all
/*Import arcmap data*/
use "../temporary/centroids_cleaned.dta"

merge 1:m prov_eng using "../temporary/match.dta"

duplicates drop prov_short, force

merge 1:m prov_short using "../temporary/potatoes.dta", generate(merge2)

/*Drop unmatched obs*/
drop if merge2 == 1

sort province year

/*Drop unnecessary variables*/

drop join_count target_fid prov_eng id prov_short similscore negative _merge merge2

save "../output/potatoes_fishnet.dta", replace

capture log close
