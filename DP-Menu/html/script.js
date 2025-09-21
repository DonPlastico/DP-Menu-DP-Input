document.addEventListener('DOMContentLoaded', function () {
    let buttonParams = [];
    let activeIndex = -1; // -1 means no item is currently selected
    let menuItems = []; // To store clickable menu items

    // Variables para controlar la velocidad de la rueda del ratón
    let isScrolling = false;
    const SCROLL_DELAY = 25; // Milisegundos entre cada movimiento permitido (ajusta a tu gusto)

    const openMenu = (data = null) => {
        let buttonsContainer = document.getElementById('buttons');
        let fondo = document.getElementById('fondo');
        let container = document.getElementById('container');
        let actionIndicators = document.getElementById('action-indicators'); // Nuevo: obtener los indicadores

        if (!buttonsContainer || !fondo || !container || !actionIndicators) return;

        let html = "";
        menuItems = []; // Reset menu items
        let menuHeader = document.getElementById('menu-header');
        let htmlHeader = "";
        let htmlButtons = "";

        data.forEach((item, index) => {
            if (!item.hidden) {
                if (item.isMenuHeader) {
                    htmlHeader = item.header; // Solo el texto del título
                } else {
                    htmlButtons += getButtonRender(item.header, item.txt || item.text || "", index, item.disabled, item.icon || "fa-solid fa-bars");
                    if (item.params) buttonParams[index] = item.params;
                    if (!item.disabled) {
                        menuItems.push({ elementId: index, params: item.params });
                    }
                }
            }
        });

        menuHeader.textContent = htmlHeader; // Usamos textContent para solo el texto
        buttonsContainer.innerHTML = htmlButtons;
        fondo.style.display = 'block';
        actionIndicators.style.display = 'flex';

        // Añadir la clase para deshabilitar eventos del ratón
        container.classList.add('disable-mouse-events');

        document.querySelectorAll('.button:not(.disabled)').forEach(button => {
            button.addEventListener('click', function () {
                postData(this.id);
            });
        });

        if (menuItems.length > 0) {
            activeIndex = 0;
            highlightItem(activeIndex);
        } else {
            activeIndex = -1;
        }
    };

    const getButtonRender = (header, message, id, isDisabled, icon) => {
        return `
            <div class="button ${isDisabled ? "disabled" : ""}" id="${id}">
                <div class="icon"><i class="${icon}"></i></div>
                <div class="content">
                    <div class="header">${header}</div>
                    ${message ? `<div class="text">${message}</div>` : ''}
                </div>
            </div>
        `;
    };

    const highlightItem = (index) => {
        if (index < 0 || index >= menuItems.length) return;

        document.querySelectorAll('.button').forEach((button) => {
            button.classList.remove('highlighted');
        });

        const targetButtonId = menuItems[index].elementId;
        const targetButton = document.getElementById(targetButtonId);

        if (targetButton) {
            targetButton.classList.add('highlighted');
            targetButton.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        }
    };

    const closeMenu = () => {
        let buttonsContainer = document.getElementById('buttons');
        let fondo = document.getElementById('fondo');
        let container = document.getElementById('container');
        let actionIndicators = document.getElementById('action-indicators'); // Nuevo: obtener los indicadores

        if (buttonsContainer) buttonsContainer.innerHTML = "";
        if (fondo) fondo.style.display = 'none';
        if (actionIndicators) actionIndicators.style.display = 'none'; // Nuevo: ocultar los indicadores

        // Remover la clase para habilitar eventos del ratón
        if (container) {
            container.classList.remove('disable-mouse-events');
        }

        buttonParams = [];
        activeIndex = -1;
        menuItems = [];
    };

    const postData = (id) => {
        fetch(`https://${GetParentResourceName()}/clickedButton`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify(parseInt(id) + 1)
        });
        closeMenu();
    };

    const cancelMenu = () => {
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            }
        });
        closeMenu();
    };

    window.addEventListener("message", (event) => {
        const data = event.data;
        if (!data) return;

        const buttons = data.data;
        const action = data.action;

        switch (action) {
            case "OPEN_MENU":
                if (buttons) openMenu(buttons);
                break;
            case "CLOSE_MENU":
                closeMenu();
                break;
            default:
                break;
        }
    });

    // Nuevo evento para la rueda del ratón (scroll)
    // *** CAMBIO CLAVE AQUÍ: { passive: false } para permitir preventDefault ***
    document.addEventListener('wheel', function (event) {
        if (menuItems.length > 0) {
            event.preventDefault(); // Previene el scroll de la página

            // Control de velocidad: Solo procesa el scroll si no está "scrolleando" ya
            if (!isScrolling) {
                isScrolling = true;

                if (event.deltaY < 0) { // Scroll hacia arriba (rueda hacia adelante)
                    activeIndex = (activeIndex - 1 + menuItems.length) % menuItems.length;
                    highlightItem(activeIndex);
                } else if (event.deltaY > 0) { // Scroll hacia abajo (rueda hacia atrás)
                    activeIndex = (activeIndex + 1) % menuItems.length;
                    highlightItem(activeIndex);
                }

                // Resetea el flag después de un breve retardo
                setTimeout(() => {
                    isScrolling = false;
                }, SCROLL_DELAY);
            }
        }
    }, { passive: false }); // <-- Esto es lo que soluciona el error de preventDefault

    // Mantener el evento keydown para Escape y Enter
    document.addEventListener('keydown', function (event) {
        if (event.key === "Escape") {
            // Solo cancelar si el menú está abierto
            if (menuItems.length > 0) {
                event.preventDefault(); // Previene que Escape abra el mapa
                event.stopPropagation(); // Evita que el evento se propague
                cancelMenu();
            }
        }
    });

    document.addEventListener('mouseup', function (event) {
        // event.button === 1 corresponde al botón central del ratón (la rueda)
        if (event.button === 1 && activeIndex !== -1) {
            event.preventDefault(); // Previene cualquier acción por defecto del navegador si la hay
            const selectedId = menuItems[activeIndex].elementId;
            postData(selectedId);
        }
    });
});