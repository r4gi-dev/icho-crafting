let recipes=[], inventory={}, selected=null, xp=0, level=1

window.addEventListener("message", (e)=> {
    const data = e.data
    if(data.action==="open") openUI(data)
    if(data.action==="updateInventory") updateInventory(data.inventory)
    if(data.action==="updateXP") updateXP(data.xp, data.level)
})

function openUI(data){
    document.getElementById("app").style.display="block"
    recipes = data.recipes||[]
    inventory = data.inventory||{}
    xp = data.xp||0
    level = data.level||1
    sortRecipes()
    renderRecipes()
    updateXP(xp, level)
    resetDetails()
}

document.addEventListener("keydown",(e)=>{if(e.key==="Escape") closeUI()})
function closeUI(){fetch(`https://${GetParentResourceName()}/close`, {method:"POST"}); document.getElementById("app").style.display="none"; document.getElementById("craftAmount").value=1; resetDetails()}

function sortRecipes(){recipes.sort((a,b)=>a.level-b.level)}
function renderRecipes(){
    const list=document.getElementById("recipeList"); list.innerHTML=""
    recipes.forEach(r=>{
        const div=document.createElement("div"); div.className="recipeItem"
        div.innerHTML=`${r.label}<span class="recipeLevel">Lv.${r.level}</span>`
        div.onclick=()=>selectRecipe(r)
        list.appendChild(div)
    })
}
function selectRecipe(r){selected=r; document.getElementById("noSelection").style.display="none"; document.getElementById("itemDetails").style.display="block"; renderDetails()}
function resetDetails(){selected=null; document.getElementById("noSelection").style.display="block"; document.getElementById("itemDetails").style.display="none"}

function renderDetails(){
    if(!selected) return
    document.getElementById("itemName").innerText=selected.label
    document.getElementById("itemIcon").src=`nui://ox_inventory/web/images/${selected.item}.png`
    document.getElementById("time").innerText=`${selected.time/1000}s`
    document.getElementById("xp").innerText=selected.xp
    document.getElementById("level").innerText=selected.level
    const container=document.getElementById("materials"); container.innerHTML=""
    let canCraft=true
    for(const mat in selected.materials){
        const need=selected.materials[mat], have=inventory[mat]||0
        const div=document.createElement("div"); div.className="materialItem"
        div.innerHTML=`<span>${mat}</span><span>${have}/${need}</span>`
        if(have<need){ div.classList.add("materialMissing"); canCraft=false } else { div.classList.add("materialEnough") }
        container.appendChild(div)
    }
    document.getElementById("craftBtn").disabled = !canCraft
}

document.getElementById("craftBtn").onclick=()=>{
    if(!selected) return
    const amount=Number(document.getElementById("craftAmount").value)
    fetch(`https://${GetParentResourceName()}/craft`, {method:"POST", body:JSON.stringify({item:selected.item, amount:amount})})
}

function updateInventory(newInv){inventory=newInv; renderDetails()}
function updateXP(newXP,newLevel){xp=newXP; level=newLevel; document.getElementById("xpfill").style.width=(xp%100)+"%"; document.getElementById("levelDisplay").innerText=level; document.getElementById("xplabel").innerText=xp+" XP"}