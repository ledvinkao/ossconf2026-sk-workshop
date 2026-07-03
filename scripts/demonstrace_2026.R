###
# OSSConf2026 - workshop Proč zpracovávat geodata v R? A jak na to?
# autor: O. Ledvinka
# datum: 2026-07-01
###


# Prerekvizity ------------------------------------------------------------

# předpokládá se, že máme nainstalovanou co nejnovější verzi R (nyní 4.6.1) - instalačku stáhneme z https://cran.r-project.org/ pro různé platformy
# rovněž se předpokládá, že máme nainstalované integrované vývojářské prostředí (IDE) RStudio - instalačku stáhneme z https://docs.posit.co/ide/user/#rstudio-ide-oss-downloads
# na OS Windows se ještě doporučuje mít také Rtools, je to ideální, pokud chceme kompilovat balíčky ze zdrojáků - instalačku stáhneme opět z https://cran.r-project.org/
# (verze Rtools by měla odpovídat verzi R)

# nyní velký předpoklad, který byl uveden i v anotaci: hodně věcí zde bude založeno na přístupu tidyverse (kdo se potřebuje naučit, je odkazován na online knihu na https://r4ds.hadley.nz/)

# pro některé případy budeme potřebovat dobré připojení k internetu


# Vybrané klávesové zkratky -----------------------------------------------

# CTRL + SHIFT + M vloží nativní pipe (pokud máme v nastavení - najdeme v Tools/Global Options.../Code)
# CTRL + SHIFT + N založí nový R skript
# CTRL + SHIFT + C zakomentuje celou řádku, na které právě jsme
# CRTL + ENTER odešle část kódu do (dolů do konzole) k vyhodnocení (stačí, když budeme na začátku nebi na konci logické části kódu)

# samozřejmě existuje možnost označit v R skriptu všechen kód (CRTL + A) a pustit vše

# zajímavá je také indentace, kterou můžeme opravit zkratkou CTRL + I, když se pokazí


# Načítání balíčků na začátku práce ---------------------------------------

# tradičně se používá funkce library()
# library(tidyverse) # název balíčku nemusí být v uvozovkách

# abychom nemuseli kontrolovat, je-li balíček nainstalovaný, a nemuseli dokola psát 'library', existuje i tato možnost:
xfun::pkg_attach2("tidyverse", # musíme mít nainstalovaný minimálně balíček xfun
                  "sf", # pro vektorová geodata
                  "terra", # pro rastrová i vektorová geodata
                  "RCzechia") # pro stahování vybraných českých geodat

# kvůli konfliktům v názvech funkcí jsme si také vysvětlili význam dvojité dvojtečky


# Závislosti balíčků na externích knihovnách ------------------------------

# zejména při načítání balíčku sf si můžeme povšimnout poznámky o prolinkování s externími knihovnami
# závislost na GDAL předurčuje možnosti načítání a ukládání (přípona názvu souboru učuje tzv. driver)
# GDAL také umožňuje tzv. řetízkování odkazů na soubory (lze tedy načítat třeba soubory, které jsou online v ZIP souboru, viz https://gdal.org/en/stable/user/virtual_file_systems.html)
# závislost na PROJ umožňuje práci se souřadnicovými referenčními systémy (CRS)
# závislost na GEOS umožňuje výpočty měr a práci s tzv. predikáty
# závislost na S2 umožňuje výpočty ploch a délek na sféře (dá se vypínat, pokud někdo nemá rád Google)


# Základní třídy související s vektorovými geodaty v R --------------------

# vyplatí se znát rozdíly mezi třídami, které se vyskytují ve vztahi k balíčku sf; pak porozumíme lépe dokumentaci, kde se vyskytují zkratky

# např. funkce st_point() akceptuje vektor se souřadnicemi
?st_point # otazník před názvem funkce spustí dokumentaci k funkci

# pokud si vymyslíme název´objektu a použijeme tzv. přiřazovací operátor (zkratka ALT + -), dostaneme do Globálního prostředí (vpavo nahoře) právě tento nový objekt
bod <- st_point(c(15, 
                  50))

# výsledkem je třída sfg, simple feature geometry
class(bod)

# vyšší třídou je sfc, simple feature column
# vzniká např. aplikací funkce st_sfc
bod <- bod |> 
  st_sfc(crs = "EPSG:4326") # zde již můžeme upřesnit, o jaký CRS se jedná

# pokud je o EPSG, lze psát jen kód (číslo, ne text v uvozovkách)

# kromě jiných tříd vidíme sfc
class(bod)

# ale už bychom měli vidět i typickou hlavičku
bod

# nejvišší třídu sf, tj. simple feature, dostaneme aplikací funkce st_sf(), pokud existuje geometrie
bod <- bod |> 
  st_sf()

# když se nám nelíbí název geometrického sloupce, lze ji přenastavit funkcí st_set_geometry()
bod <- bod |> 
  st_set_geometry("geom")

bod

# tvoří se sf, ale k tomu jen třída data.frame
bod |> 
  class()

# vylepšený datový rámec, tj. tibble, má lepší tisk do konzole, ale také jiné vylepšené vlastnosti, ke kterým se nedostaneme
# sf s třídou tibble může vzniknout následně:
bod <- bod |> 
  as_tibble() |> # zde je sf konvertována na tibble
  st_sf() # což pak lze opět převést na sf

# podívejme se nyní na třídy
bod |> 
  class()


# Přidání atributů --------------------------------------------------------

# ke geometrickému sloupci přidáme nové sloupce (třeba numerické, textové apod.)
# klasicky se nové sloupce do datového rámce přidávají např. operátorem $
# bod$nazev <- "Kourim"

# ale tidyverse přístup umožňuje přidávat sloupce přes funkci mutate()
bod <- bod |> 
  mutate(nazev = "Kourim",
         typ = "astronomicky stred Evropy")


# Kreslení vektorových geodat ---------------------------------------------

# součástí tidyverse je balíček ggplot2, který obsahuje funkci geom_sf()
ggplot() + 
  geom_sf(data = bod)

# nastává rozdíl při kreslení bodu klasickým způsobem funkcí geom_point()
ggplot(tibble(x = 15,
              y = 50)) + 
  geom_point(aes(x = x,
                 y = y))

# to bylo kreslení statických map (v záložce Plots)
# existují ale i možnosti kreslení tzv. dynamických map (v záložce Viewer)
# demonstrujme to na funkcích balíčku tmap
library(tmap)

# starši verze tmap pro přepínání mezi statickými a dynamickými mapami vyžadovaly funkci tmap_mode()
# v nových verzích existuje zkratka ttm()
# když budeme pořád opakovat následující řádek, můžeme si všimnout, že se zvýrazňuje 'plot' nebo 'view'
ttm()

# při kreslení ve smyslu tmap, musíme napřed uvést funkcí tm_shape(), co chceme kreslit (tedy nějaký dříve vytvořený objekt)
# následnými funkcemi zadáváme, jak se to má kreslit
tm_shape(bod) +
  tm_dots()

# logika připomíná ggplot, dokonce i operátory + se zde objevují (pozor na záměny s pipem!)


# Kreslení více objektů najednou ------------------------------------------

# napřed jsme si stáhli polygon území Česka prostřednictvím funkce RCzechia::republika()
hranice <- republika()

# opět jsme převedli na tibble sf
hranice <- hranice |> 
  as_tibble() |> 
  st_sf()

# jak nyní vypadá objekt 'hranice' v konzoli?
hranice

# a jdeme na kreslení
# rozdíl v ggplot je v tom, že na sebe vrstvíme více objektů operátorem +
ggplot() + 
  geom_sf(data = hranice,
          col = "purple",
          fill = NA) + 
  geom_sf(data = bod,
          size = 2,
          col = "red") + 
  coord_sf(crs = "ESRI:54024") # někdy může operátor + přidat i jiné chování CRS, přednastavené šablony apod.


# Míry a jednotky ---------------------------------------------------------

# vypočítejme plochu území Česka
hranice <- hranice |> 
  mutate(geom2 = st_transform(geometry, # mutate() může přidat sloupec na základě jiného sloupce; de přidáváme druhou, transformovanou, geometrii 
                              3035),
         a = st_area(geom2)) # ze druhé geometrie (kde by měla být splněna plochojevnost), funkcí st_area() dostaneme plochu v m^2

# funkce balíčku units můžeme využít k převodu jednotek
hranice <- hranice |> 
  mutate(a2 = units::set_units(a, km2))

hranice <- hranice |> 
  mutate(a3 = units::set_units(a, ft2))

# co nyní máme v atributech?
hranice


# Ukládání vektorových geodat do souborů ----------------------------------

# k ukládání vektorových geodat slouží v sf funkce write_sf() nebo st_write()
bod |> 
  write_sf("results/nas_bod.gpkg") # pokud jsme v R projektu, lze se v cestě k souboru odkazovat relativně na složku, kterou tam máme (ať máme vše uspořádáno)

# soubory typu geopackage mohou obsahovat více vektorových vrstev najednou (i v různých CRS) a třeba i jen tabulky bez geometrie
# co je obsahem geopackage, zjistíme např. funkcí st_layers()
st_layers("results/nas_bod.gpkg")

# protože je k jsou k ukládání využívány drivery knihovny GDAL, lze volit i přípony kml, geojson, kml apod.


# Tvorba vektorových geodat z tabulek obsahujících souřadnice -------------

# jako příklad jsme si vzali metadata vodoměrných stanic, která jsou publikována v JSON souboru online
# funkce jsonlite::fromJSON konvertuje obsah JSON souboru na seznam
meta <- jsonlite::fromJSON("https://opendata.chmi.cz/hydrology/historical/metadata/meta1.json")

# z prvků tohoto seznamu lze pak vytvořit tabulku
meta <- meta$data$data$values |> # toto je matice s textovými řetězci
  as.data.frame() |> 
  as_tibble() |> # převádíme na tibble
  set_names(meta$data$data$header |> # a nastavujeme hlavičku tabulky
              str_split_1(",")) # kde vycházíme z jednoprvkového vektoru, který si ale můžeme podle čárky rozdělit

# tato tabulka obsahuje souřadnice ve sloupcích GEOGR1 a GEOGR2
# funkcí st_as_sf() můžeme získat rovnou sf
meta <- meta |> 
  st_as_sf(coords = c("GEOGR2", # pozor na obrácené pořadí souřadnic v tabulce
                      "GEOGR1"), # dříve byly vyžadovány numerické sloupce se souřadnicemi, ale dnes už ani textové sloupce jaksi nevadí
           crs = 4326)

# jak bychom docílili toho, aby sloupce se souřadnicemi zůstaly v atributech?
# viz argument 'remove' ve funkci st_as_sf()
?st_as_sf

# nakresleme výsledek
# u tmap stále ještě jsme v módu 'view'
tm_shape(meta) + 
  tm_dots(size = 0.7,
          fill = "red")


# Predikáty ---------------------------------------------------------------

# řekněmě, že chceme zjistit, kolik vodoměrných stanic máme mimo území Česka
# hranaté závorky slouží jako zkratka funkce st_filter(), což je příbuzná fukce st_join() pro prostorové propojování
meta_mimo <- meta[hranice, # filtrování hranatými závorkami připomíná starou známou práci s řádky základního R, jenom zde dodáváme polygon na první místo
                  op = st_disjoint] # na druhém místě může být zvolený predikát - st_intersects vybere body uvnitř polygonu, st_disjoint vybere body mimo polygon

# takových stanice je aktuálně 11 (většinou z území Polska)
meta_mimo

# podívejme se ještě na seznam predikátů
?st_disjoint


# Rastrová geodata --------------------------------------------------------

# ukázky s rastrovými geodaty jsme nestihli, ale odkazovali dívali jsme se na soubory klimatických scénářů, které vznikly v rámci projektu PERUN
# viz https://www.perun-klima.cz/scenare/

# na webových stránkách se nacházejí ZIP soubory, z nichž si můžeme funkcí terra::rast() vzít rastrová geodata do prostředí R pro další zpracování

# se zmiňovanými GDAL řetízky v odkazech to lze provádět např. takto:
r <- rast("/vsizip/vsicurl/https://www.perun-klima.cz/scenare/data/SSP245_SRA_year_asc.zip/SSP245_SRA_2021-2040_year.asc")

# pozor! zde je třeba respektovat malá a velká písmena

# podívejme se v konzoli nakonec na hlavičku spjatou s tímto objektem třídy SpatRaster, resp. Formal class SpatRaster
r

# chybí CRS, tak jej můžeme přiřadit
crs(r) <- "epsg:32633" # známe z webových stránek PERUNa

r
