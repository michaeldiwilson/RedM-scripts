let recipes = {};
let items = [];
let inventoryMap = {};
let currentCategory = 'all';
let benchId = null;
let isCrafting = false;
let recipeQtys = {};

function getImage(itemName) {
    return `nui://rsg-inventory/html/images/${itemName}.png`;
}

function buildInventoryMap(itemList) {
    const map = {};
    for (const item of itemList) {
        if (item && item.name) {
            map[item.name] = (map[item.name] || 0) + (item.amount || 0);
        }
    }
    return map;
}

// ── NUI Messages ──
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        recipes = data.recipes || {};
        items = data.items || [];
        inventoryMap = buildInventoryMap(items);
        benchId = data.benchId;
        recipeQtys = {};

        document.getElementById('crafting-title').textContent = data.title || 'Crafting';
        document.getElementById('crafting-ui').classList.remove('hidden');
        renderCategoryTabs();
        renderInventory();
        renderRecipes();
    }

    if (data.action === 'close') {
        document.getElementById('crafting-ui').classList.add('hidden');
    }

    if (data.action === 'updateInventory' || data.action === 'craftDone') {
        if (data.items) {
            items = data.items;
            inventoryMap = buildInventoryMap(items);
        } else if (data.inventory) {
            inventoryMap = data.inventory;
        }
        isCrafting = false;
        hideProgress();
        renderInventory();
        renderRecipes();
    }

    if (data.action === 'craftProgress') {
        showProgress(data.label, data.duration);
    }
});

// ── Render Inventory (Left Panel) ──
function renderInventory() {
    const grid = document.getElementById('inventory-grid');
    grid.innerHTML = '';

    for (const item of items) {
        if (!item || !item.name || item.amount <= 0) continue;

        const slot = document.createElement('div');
        slot.className = 'inv-slot';
        slot.dataset.item = item.name;

        const label = item.name.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
        slot.innerHTML = `
            <img src="${getImage(item.name)}" alt="${item.name}" onerror="this.style.display='none'">
            <span class="inv-count">${item.amount}</span>
            <span class="inv-label">${label}</span>
        `;
        grid.appendChild(slot);
    }
}

// ── Render Category Tabs ──
function renderCategoryTabs() {
    const container = document.getElementById('category-tabs');
    container.innerHTML = '';

    const categories = new Set(['all']);
    for (const [key, recipe] of Object.entries(recipes)) {
        categories.add(recipe.category || 'general');
    }

    const labels = {
        all: 'All',
        general: 'General',
        hunting: 'Hunting',
        moonshine: 'Moonshine',
        wagon_parts: 'Wagon Parts',
        wagon_assembly: 'Wagons',
        tanning: 'Tanning',
    };

    for (const cat of categories) {
        const btn = document.createElement('button');
        btn.className = `cat-tab ${cat === currentCategory ? 'active' : ''}`;
        btn.textContent = labels[cat] || cat;
        btn.addEventListener('click', () => {
            currentCategory = cat;
            document.querySelectorAll('.cat-tab').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            renderRecipes();
        });
        container.appendChild(btn);
    }
}

// ── Render Recipes (Right Panel) ──
function renderRecipes() {
    const list = document.getElementById('recipes-list');
    list.innerHTML = '';

    for (const [key, recipe] of Object.entries(recipes)) {
        const cat = recipe.category || 'general';
        if (currentCategory !== 'all' && cat !== currentCategory) continue;

        let canCraft = true;
        const ingredientHTML = [];

        for (const [item, needed] of Object.entries(recipe.inputs)) {
            const have = inventoryMap[item] || 0;
            const hasEnough = have >= needed;
            if (!hasEnough) canCraft = false;

            const itemLabel = item.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
            ingredientHTML.push(`
                <div class="ingredient ${hasEnough ? 'has' : 'missing'}">
                    <img src="${getImage(item)}" alt="${item}" onerror="this.style.display='none'">
                    <span>${itemLabel}</span>
                    <span style="font-weight:bold">${have}/${needed}</span>
                </div>
            `);
        }

        const outputQty = recipe.qty > 1 ? ` x${recipe.qty}` : '';
        const qty = recipeQtys[key] || 1;

        const card = document.createElement('div');
        card.className = `recipe-card ${canCraft ? '' : 'disabled'}`;
        card.dataset.key = key;
        card.innerHTML = `
            <div class="recipe-top">
                <img class="recipe-icon" src="${getImage(recipe.output)}" alt="${recipe.output}" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22/>'">
                <div class="recipe-info">
                    <div class="recipe-name">${recipe.label}${outputQty}</div>
                    <div class="recipe-output">${recipe.output.replace(/_/g, ' ')}</div>
                </div>
            </div>
            <div class="recipe-ingredients">
                ${ingredientHTML.join('')}
            </div>
            <div class="recipe-bottom">
                <div class="qty-controls">
                    <button class="qty-btn" data-key="${key}" data-delta="-1">-</button>
                    <div class="qty-display" id="qty-${key}">${qty}</div>
                    <button class="qty-btn" data-key="${key}" data-delta="1">+</button>
                </div>
                <button class="craft-btn ${canCraft ? '' : 'disabled'}" data-key="${key}" ${canCraft ? '' : 'disabled'}>CRAFT</button>
            </div>
        `;

        // Hover: highlight ingredients on left panel
        card.addEventListener('mouseenter', () => highlightIngredients(key));
        card.addEventListener('mouseleave', () => clearHighlights());

        list.appendChild(card);
    }

    // Attach qty button listeners
    document.querySelectorAll('.qty-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const key = btn.dataset.key;
            const delta = parseInt(btn.dataset.delta);
            const current = recipeQtys[key] || 1;
            const newQty = Math.max(1, Math.min(99, current + delta));
            recipeQtys[key] = newQty;
            document.getElementById(`qty-${key}`).textContent = newQty;
        });
    });

    // Attach craft button listeners
    document.querySelectorAll('.craft-btn:not(.disabled)').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            if (isCrafting) return;
            const key = btn.dataset.key;
            const qty = recipeQtys[key] || 1;
            startCraft(key, qty);
        });
    });

    if (list.children.length === 0) {
        list.innerHTML = '<div style="text-align:center; color:#666; padding:40px;">No recipes available in this category</div>';
    }
}

// ── Highlight Ingredients ──
function highlightIngredients(recipeKey) {
    clearHighlights();
    const recipe = recipes[recipeKey];
    if (!recipe) return;

    for (const [item, needed] of Object.entries(recipe.inputs)) {
        const have = inventoryMap[item] || 0;
        const slots = document.querySelectorAll(`.inv-slot[data-item="${item}"]`);
        slots.forEach(slot => {
            slot.classList.add(have >= needed ? 'highlight-has' : 'highlight-missing');
        });
    }
}

function clearHighlights() {
    document.querySelectorAll('.inv-slot').forEach(slot => {
        slot.classList.remove('highlight-has', 'highlight-missing');
    });
}

// ── Crafting ──
function startCraft(recipeKey, qty) {
    if (isCrafting) return;
    isCrafting = true;
    fetch('https://mike-crafting/craft', {
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
        if (pct >= 100) clearInterval(interval);
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

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeUI();
});
