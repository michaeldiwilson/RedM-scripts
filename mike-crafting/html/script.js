let recipes = {};
let inventory = {};
let currentCategory = 'all';
let benchId = null;
let isCrafting = false;

// Category mapping for each recipe
const categoryMap = {
    copper_pot: 'moonshine',
    copper_coil: 'moonshine',
    oak_barrel: 'moonshine',
    portable_still: 'moonshine',
    lockpick: 'general',
    tanning_rack: 'general',
    rope: 'general',
    cloth: 'general',
    wagon_wheel: 'wagon_parts',
    wagon_axle: 'wagon_parts',
    wagon_frame: 'wagon_parts',
    wagon_seat: 'wagon_parts',
    wagon_kit_work: 'wagon_assembly',
    wagon_kit_covered: 'wagon_assembly',
    wagon_kit_hunting: 'wagon_assembly',
    cure_rabbit: 'tanning',
    cure_deer: 'tanning',
    cure_boar: 'tanning',
    cure_elk: 'tanning',
    cure_cougar: 'tanning',
    cure_wolf: 'tanning',
    cure_bear: 'tanning',
    cure_bison: 'tanning',
    cure_sheep: 'tanning',
    cure_goat: 'tanning',
    cure_coyote: 'tanning',
};

// Image path helper
function getImage(itemName) {
    return `nui://rsg-inventory/html/images/${itemName}.png`;
}

// Listen for messages from Lua
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        recipes = data.recipes || {};
        inventory = data.inventory || {};
        benchId = data.benchId;
        document.getElementById('crafting-ui').classList.remove('hidden');
        renderRecipes();
    }

    if (data.action === 'close') {
        document.getElementById('crafting-ui').classList.add('hidden');
    }

    if (data.action === 'updateInventory') {
        inventory = data.inventory || {};
        renderRecipes();
    }

    if (data.action === 'craftProgress') {
        showProgress(data.label, data.duration);
    }

    if (data.action === 'craftDone') {
        isCrafting = false;
        hideProgress();
        inventory = data.inventory || inventory;
        renderRecipes();
    }
});

// Category buttons
document.querySelectorAll('.cat-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentCategory = btn.dataset.cat;
        renderRecipes();
    });
});

function renderRecipes() {
    const grid = document.getElementById('recipes-grid');
    grid.innerHTML = '';

    for (const [key, recipe] of Object.entries(recipes)) {
        const cat = categoryMap[key] || 'general';
        if (currentCategory !== 'all' && cat !== currentCategory) continue;

        // Check if player has all ingredients
        let canCraft = true;
        const ingredientHTML = [];

        for (const [item, needed] of Object.entries(recipe.inputs)) {
            const have = inventory[item] || 0;
            const hasEnough = have >= needed;
            if (!hasEnough) canCraft = false;

            const itemLabel = item.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
            ingredientHTML.push(`
                <div class="ingredient ${hasEnough ? 'has' : 'missing'}">
                    <img src="${getImage(item)}" alt="${item}" onerror="this.style.display='none'">
                    <span class="ing-name">${itemLabel}</span>
                    <span class="ing-count">${have}/${needed}</span>
                </div>
            `);
        }

        const outputQty = recipe.qty > 1 ? `x${recipe.qty}` : '';
        const outputImage = getImage(recipe.output);

        const card = document.createElement('div');
        card.className = `recipe-card ${canCraft ? '' : 'disabled'}`;
        card.innerHTML = `
            <div class="recipe-top">
                <img class="recipe-icon" src="${outputImage}" alt="${recipe.output}" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22/>'">
                <div class="recipe-info">
                    <div class="recipe-name">${recipe.label || recipe.output}</div>
                    <div class="recipe-output">${recipe.output} ${outputQty}</div>
                </div>
            </div>
            <div class="recipe-ingredients">
                ${ingredientHTML.join('')}
            </div>
            <div class="qty-row">
                <input type="number" class="qty-input" value="1" min="1" max="99" onclick="event.stopPropagation()">
                <button class="craft-btn ${canCraft ? '' : 'disabled'}" ${canCraft ? '' : 'disabled'}>CRAFT</button>
            </div>
        `;

        if (canCraft) {
            const craftBtn = card.querySelector('.craft-btn');
            const qtyInput = card.querySelector('.qty-input');
            craftBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                if (isCrafting) return;
                const qty = parseInt(qtyInput.value) || 1;
                startCraft(key, qty);
            });
        }

        grid.appendChild(card);
    }

    if (grid.children.length === 0) {
        grid.innerHTML = '<div style="grid-column: 1/-1; text-align: center; color: #666; padding: 40px;">No recipes available in this category</div>';
    }
}

function startCraft(recipeKey, qty) {
    if (isCrafting) return;
    isCrafting = true;
    fetch(`https://mike-crafting/craft`, {
        method: 'POST',
        body: JSON.stringify({ benchId, recipeKey, qty })
    });
}

function showProgress(label, duration) {
    const container = document.getElementById('progress-container');
    const bar = document.getElementById('progress-bar');
    const text = document.getElementById('progress-text');

    container.classList.remove('hidden');
    text.textContent = label;
    bar.style.width = '0%';

    const startTime = Date.now();
    const interval = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const pct = Math.min((elapsed / duration) * 100, 100);
        bar.style.width = pct + '%';

        if (pct >= 100) {
            clearInterval(interval);
        }
    }, 50);
}

function hideProgress() {
    document.getElementById('progress-container').classList.add('hidden');
    document.getElementById('progress-bar').style.width = '0%';
}

function closeUI() {
    document.getElementById('crafting-ui').classList.add('hidden');
    fetch('https://mike-crafting/close', { method: 'POST', body: '{}' });
}

// ESC to close
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeUI();
    }
});
