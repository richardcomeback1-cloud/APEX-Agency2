let lastFundBigInt = null;

$(document).ready(function () {

    window.addEventListener('message', function (event) {
        var data = event.data
        if (data.type == "main") {

            current_ranks = data.grade;

            $(`.box-main`).fadeIn();
            $(`.box-main`).html(`
                <div class="container apex-modern"> 
                    <div class="header">   
                        <div class="header-glow"></div>
                        <div class="header-circle dialog-icon-container icon-float">
                            <iconify-icon icon="line-md:account"></iconify-icon>
                        </div>
                        <div class="header-title">เมนูหลักในการจัดการสมาชิก</div>
                        <div class="header-details">ระบบจัดการสมาชิก [ <span> ${ data.title } </span> ]</div>
                        <div class="close-menu"> <iconify-icon icon="line-md:close"></iconify-icon> </div>
                    </div>

                    <div class="container-fund">
                        <span id="header-fund">ทรัพย์สินหน่วยงาน</span>
                        <span id="fund-live" class="live-dot"><iconify-icon icon="line-md:loading-twotone-loop"></iconify-icon> อัพเดทตลอด</span>
                        <span id="fund">$${ App.formatMoney(data.fund) }</span>
                        <span id="fund-delta" class="fund-delta"></span>
                        <div class="fund-action-row">
                            <input type="text" inputmode="numeric" name="dialog-count" id="dialog-fund" placeholder="กรอกจำนวนเงิน" autocomplete="off"> 
                            <div class="btn-deposit action-btn"><iconify-icon icon="line-md:plus"></iconify-icon><span>ฝากเงิน</span></div>
                            <div class="btn-withdraw action-btn"><iconify-icon icon="line-md:minus"></iconify-icon><span>ถอนเงิน</span></div>
                        </div>
                    </div>

                    <div class="container-search"> 
                        <i class="fa fa-search"></i> 
                        <input type="text" name="dialog-search" id="dialog-search" placeholder="ค้นหาสมาชิก"> 
                    </div>

                    <div class="container-player">
                        <div class="header-player">รายชื่อทั้งหมดในหน่วยงาน<span>แพทย์</span></div>
                        <div class="player-list"></div>
                    </div>

                    <div class="footer-actions">
                        <div class="btn-invite-job"><iconify-icon icon="line-md:person-add"></iconify-icon>เพิ่มสมาชิกในหน่วยงาน</div>
                        <div class="btn-all-job"><iconify-icon icon="line-md:account"></iconify-icon> ${ data.player }</div>
                    </div>
                </div>
                <div class="container-dialog"></div>
            `);    

            $(".close-menu").click(function() {
                App.sounds("button_click");
                $.post(`https://${GetParentResourceName()}/exit`, JSON.stringify({}));
                $(`.box-main`).fadeOut();
            });

            $(document).off('click.apexFund', '.btn-deposit').on('click.apexFund', '.btn-deposit', function() {
                App.submitFundAction('deposit', data.title);
            });

            $(document).off('click.apexFund', '.btn-withdraw').on('click.apexFund', '.btn-withdraw', function() {
                App.submitFundAction('withdraw', data.title);
            });

            App.update_agency(data.title , data.agency)
            App.updateFundDisplay(data.fund || 0, true)
            App.bindNumericInput("#dialog-fund")

            $("#dialog-search").keyup(function() {  
                var str = $("#dialog-search").val().toLowerCase();
                if (str.length <= 0) {
                    $("[data-fullname]").show();
                } else {
                    $("[data-fullname]").hide().filter('[data-fullname*="'+str+'"]').show();
                }
            });

            $(".btn-invite-job").click(function() {
                App.sounds("button_click");
                App.invite_agency(data.title)
                $(`.container`).addClass('blur');
            });
        
        }
        if (data.type === "update_fund") {
            App.updateFundDisplay(data.fund || 0, false);
        }
        if (data.type === "update_agency") {
            if (Array.isArray(data.grade)) {
                current_ranks = data.grade;
            }
            App.update_agency(data.job, data.agency || []);
            $(`.btn-all-job`).html(`${ data.player || 0 }`);
        }
    })

    document.onkeyup = function (data) {
        if (data.which == 27) {
            $.post(`http://${GetParentResourceName()}/exit`, JSON.stringify({}));
            $(`.box-main`).fadeOut();
            return
        }
    };
})

const App = {
    selected_rank: null,
    fundInputValue: "",

    submitFundAction : function(action, job) {
        App.sounds("button_click");

        const input = document.getElementById('dialog-fund');
        if (!input) return;

        input.blur();

        setTimeout(function() {
            const currentDomValue = String(input.value || '').replace(/\D/g, '');
            const rawAmount = currentDomValue || App.fundInputValue || '';
            input.value = '';
            App.fundInputValue = '';

            const amount = App.parseAmountInput(rawAmount);
            if (amount === null) return;

            $.post(`https://${GetParentResourceName()}/${action}`, JSON.stringify({
                job: job,
                amount: amount,
            }));
        }, 0);
    },

    updateFundDisplay : function(nextFund, isInitial) {
        const displayText = App.formatMoney(nextFund);
        $("#fund").html(`$${displayText}`);

        const currentBig = App.toBigIntSafe(nextFund);
        if (isInitial || lastFundBigInt === null || currentBig === null) {
            lastFundBigInt = currentBig;
            $("#fund").removeClass('fund-raise fund-drop');
            $("#fund-delta").removeClass('show up down').text('');
            return;
        }

        const deltaBig = currentBig - lastFundBigInt;
        lastFundBigInt = currentBig;

        $("#fund").removeClass('fund-raise fund-drop');
        if (deltaBig > 0n) {
            $("#fund").addClass('fund-raise');
            $("#fund-delta").removeClass('down').addClass('show up').text(`+${App.formatMoney(deltaBig.toString())}`);
        } else if (deltaBig < 0n) {
            const absDelta = (deltaBig < 0n ? -deltaBig : deltaBig);
            $("#fund").addClass('fund-drop');
            $("#fund-delta").removeClass('up').addClass('show down').text(`-${App.formatMoney(absDelta.toString())}`);
        } else {
            $("#fund-delta").removeClass('show up down').text('');
        }

        setTimeout(function() {
            $("#fund").removeClass('fund-raise fund-drop');
            $("#fund-delta").removeClass('show up down').text('');
        }, 1000);
    },

    bindNumericInput : function(selector) {
        const el = $(selector);
        if (!el.length) return;

        const syncValue = function(node) {
            const clean = String($(node).val() || '').replace(/\D/g, '');
            $(node).val(clean);
            if (selector === '#dialog-fund') {
                App.fundInputValue = clean;
            }
        };

        el.off('.apexNumeric');
        el.on('input.apexNumeric change.apexNumeric keyup.apexNumeric paste.apexNumeric', function() {
            syncValue(this);
        });

        if (selector === '#dialog-fund') {
            App.fundInputValue = String(el.val() || '').replace(/\D/g, '');
        }
    },

    parseAmountInput : function(raw) {
        const digits = String(raw || '').replace(/\D/g, '');
        if (!digits) return null;
        const normalized = digits.replace(/^0+(?!$)/, '');
        if (!normalized || normalized === '0') return null;
        return normalized;
    },

    toBigIntSafe : function(value) {
        try {
            const s = String(value ?? '').trim().replace(/[,\s]/g, '');
            if (!s || s === '-' || s === '+') return null;
            if (!/^[+-]?\d+$/.test(s)) return null;
            return BigInt(s);
        } catch (e) {
            return null;
        }
    },

    formatMoney : function(value) {
        const bi = App.toBigIntSafe(value);
        if (bi === null) {
            return App.format_number(parseInt(value || 0, 10) || 0, 0);
        }

        let negative = bi < 0n;
        let digits = (negative ? (-bi) : bi).toString();
        digits = digits.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        return negative ? `-${digits}` : digits;
    },

   
	update_agency : function(job , agency) {
        $(".player-list").html("");
        $.each(agency, function(k, v) {
            const rankClass = App.getRankClass(v.grade_label || '')
            $(".player-list").append(`
                <div class="box-player" data-fullname="${ v.fullname.toLowerCase() }">
                    <div class="player-meta">
                        <div class="player-name">${ v.fullname }</div>
                        <div class="player-job ${rankClass}">${ v.grade_label }</div>
                    </div>
                    <div class="player-actions">
                        <div class="btn-canrank" title="เปลี่ยนยศ" data-identifier="${ v.identifier }" data-job="${ job }" onclick="App.open_ranks(this)"><iconify-icon icon="line-md:arrow-up-circle"></iconify-icon></div>
                        <div class="btn-canbonus" title="ให้โบนัส" data-identifier="${ v.identifier }" data-job="${ job }" onclick="App.open_bonus(this)"><iconify-icon icon="solar:money-bag-linear"></iconify-icon></div>
                        <div class="btn-canfire" title="ไล่ออก" data-identifier="${ v.identifier }" data-job="${ job }" onclick="App.sack_agency(this)"><iconify-icon icon="line-md:close-circle"></iconify-icon></div>
                    </div>
                </div>
            `);
        });
	},

    getRankClass : function(label) {
        const t = String(label || '').toLowerCase();
        if (t.includes('boss') || t.includes('ผอ') || t.includes('director')) return 'rank-boss';
        if (t.includes('chief') || t.includes('หัวหน้า') || t.includes('manager')) return 'rank-chief';
        if (t.includes('senior') || t.includes('sr') || t.includes('อาวุโส')) return 'rank-senior';
        return 'rank-member';
    },

    invite_agency : function(job) {
        $(`.container`).addClass('blur');
        $(".container-dialog").fadeIn();
        $(".container-dialog").html(`
            <div class="bonus-dialog invite-dialog">
                <div class="dialog-content">
                    <div class="dialog-header-section">
                        <div class="dialog-icon-wrapper">
                            <div class="dialog-icon-container">
                                <iconify-icon icon="gridicons:menus"></iconify-icon>
                            </div>
                            <div class="dialog-title-section">
                                <p> Invite Member </p>
                                <p> ใส่ไอดีที่ต้องการจะเชิญ </p>
                            </div>
                        </div>
                        <div class="dialog-content-section">
                            <div class="dialog-form-row">
                                <div class="dialog-input-box">
                                    <input type="text" inputmode="numeric" placeholder="ไอดีผู้เล่น" id="dialog-id-invite" autocomplete="off">
                                </div>
                                <div class="dialog-confirm-btn btn-confirm-invite">
                                    <p> ยืนยัน </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="close-menu btn-cancel-invite">
                    <iconify-icon icon="famicons:close-sharp"></iconify-icon>
                </div>
            </div>
        `);
    
        $(".btn-cancel-invite").click(function() {
            App.sounds("button_click");
            $(".container-dialog").fadeOut();
            $(`.container`).removeClass('blur');
        });
    
        App.bindNumericInput("#dialog-id-invite");

        $(".btn-confirm-invite").click(function() {
            App.sounds("button_click");
            const targetId = App.parseAmountInput($("#dialog-id-invite").val());
            if (targetId === null) return;
            $(".container-dialog").fadeOut();
            $(`.container`).removeClass('blur');
            $.post(`https://${GetParentResourceName()}/hire`, JSON.stringify({
                job: job,
                id: targetId,
            }), function() {});
            $("#dialog-id-invite").val('');
        });
	},


    sack_agency : function(t) {
        App.sounds("button_click");
        var identifier = t.dataset.identifier
        var job = t.dataset.job
        var playerName = $(t).parent().find(".player-name").text();
        $(`.container`).addClass('blur');
        $(".container-dialog").fadeIn();
        $(".container-dialog").html(`
            <div class="bonus-dialog kick-dialog">
                <div class="dialog-content">
                    <div class="dialog-header-section">
                        <div class="dialog-icon-wrapper">
                            <div class="dialog-icon-container">
                                <iconify-icon icon="mdi:question-mark"></iconify-icon>
                            </div>
                            <div class="dialog-title-section">
                                <p> Kick Member </p>
                                <p> คุณแน่ใจหรือไม่ที่จะไล่ ${playerName} ออก? </p>
                            </div>
                        </div>
                        <div class="dialog-content-section">
                            <div class="dialog-form-row">
                                <div class="dialog-confirm-btn btn-confirm-kick" style="flex: 1 0 0;">
                                    <p> ยืนยัน </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="close-menu btn-cancel-kick">
                    <iconify-icon icon="famicons:close-sharp"></iconify-icon>
                </div>
            </div>
        `);
    
        $(".btn-cancel-kick").click(function() {
            App.sounds("close_ui");
            $(".container-dialog").fadeOut();
            $(`.container`).removeClass('blur');
        });
    
        $(".btn-confirm-kick").click(function() {
            App.sounds("button_click");
            $(".container-dialog").fadeOut();
            $(`.container`).removeClass('blur');
            $.post(`https://${GetParentResourceName()}/fire`, JSON.stringify({
                job: job,
                identifier: identifier
            }), function() {});
        });
	},

    open_ranks : function(t) {
        App.sounds("button_click");
        var identifier = t.dataset.identifier
        var job = t.dataset.job
        App.selected_rank = null;
        $(`.container`).addClass('blur');
        $(".container-dialog").fadeIn();
        $(".container-dialog").html(`
            <div class="rank-dialog">
                <div class="dialog-content">
                    <div class="dialog-header-section">
                        <div class="dialog-icon-wrapper">
                            <div class="dialog-icon-container">
                                <iconify-icon icon="pepicons-pop:down-up"></iconify-icon>
                            </div>
                            <div class="dialog-title-section">
                                <p> Manager Action </p>
                                <p> เลือกตำแหน่งที่ต้องการ </p>
                            </div>
                        </div>
                        <div class="dialog-content-section">
                            <div class="dialog-form-row">
                                <div class="dialog-input-box">
                                    <div class="rank-dropdown">
                                        <button onclick="App.toggleRankDropdown()" class="rank-select-btn" id="text-choose-rank">เลือกตำแหน่ง</button>
                                        <div id="rankDropdown" class="rank-dropdown-list">
                                            <div class="rank-list"></div>
                                        </div>
                                    </div>
                                </div>
                                <div class="dialog-confirm-btn btn-confirm-rank">
                                    <p> ยืนยัน </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="close-menu btn-cancel-rank">
                    <iconify-icon icon="famicons:close-sharp"></iconify-icon>
                </div>
            </div>
        `);

        // Populate rank options
        if (current_ranks && current_ranks.length > 0) {
            var firstRank = current_ranks[0];
            $("#text-choose-rank").text(firstRank.grade_label);
            App.selected_rank = firstRank.grade;
            
            $.each(current_ranks, function(k, v) {
                $(".rank-list").append(`
                    <a onclick="App.chooseRank(${v.grade}, '${v.grade_label}')">${v.grade_label}</a>
                `);
            });
        }

        $(".btn-cancel-rank").click(function() {
            App.sounds("close_ui");
            $(".container-dialog").fadeOut();
            $(`.container`).removeClass('blur');
        });

        $(".btn-confirm-rank").click(function() {
            App.sounds("button_click");
            if (App.selected_rank !== null) {
                $(".container-dialog").fadeOut();
                $(`.container`).removeClass('blur');

                $.post(`https://${GetParentResourceName()}/set_rank`, JSON.stringify({
                        identifier: identifier,
                        rank: App.selected_rank,
                        job: job
                }), function() {});
            }
        });

        // Close dropdown when clicking outside
        $(document).on('click', function(event) {
            if (!$(event.target).closest('.rank-dropdown').length) {
                $("#rankDropdown").removeClass("show");
            }
        });
	},

    toggleRankDropdown : function() {
        App.sounds("button_click");
        $("#rankDropdown").toggleClass("show");
    },

    chooseRank : function(rank, rankLabel) {
        App.sounds("button_click");
        App.selected_rank = rank;
        $("#text-choose-rank").text(rankLabel);
        $("#rankDropdown").removeClass("show");
    },

    open_bonus : function(t) {
        App.sounds("button_click");
        var identifier = t.dataset.identifier
        var job = t.dataset.job
        $(`.container`).addClass('blur');
        $(".container-dialog").fadeIn();
        $(".container-dialog").html(`
            <div class="bonus-dialog">
                <div class="dialog-content">
                    <div class="dialog-header-section">
                        <div class="dialog-icon-wrapper">
                            <div class="dialog-icon-container">
                                <iconify-icon icon="solar:wallet-money-linear"></iconify-icon>
                            </div>
                            <div class="dialog-title-section">
                                <p> Give Bonus </p>
                                <p> ใส่จำนวนเงินที่จะให้ </p>
                            </div>
                        </div>
                        <div class="dialog-content-section">
                            <div class="dialog-form-row">
                                <div class="dialog-input-box">
                                    <input type="text" inputmode="numeric" placeholder="จำนวนเงิน" id="dialog-count-bonus" autocomplete="off">
                                </div>
                                <div class="dialog-confirm-btn btn-confirm-bonus">
                                    <p> ยืนยัน </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="close-menu btn-cancel-bonus">
                    <iconify-icon icon="famicons:close-sharp"></iconify-icon>
                </div>
            </div>
        `);
    
        $(".btn-cancel-bonus").click(function() {
            App.sounds("close_ui");
            $(".container-dialog").fadeOut();
            $(`.container`).removeClass('blur');
        });
    
        App.bindNumericInput("#dialog-count-bonus");

        $(".btn-confirm-bonus").click(function() {
            App.sounds("button_click");

            const amount = App.parseAmountInput($("#dialog-count-bonus").val());
            if (amount === null) return;

            $(".container-dialog").fadeOut();
            $(`.container`).removeClass('blur');

            $.post(`https://${GetParentResourceName()}/givebonus`, JSON.stringify({
                    identifier: identifier,
                    amount: amount,
                    job: job
            }), function(cb) {
                if (cb) {
                    $(`#fund`).html(`$${ App.format_number(cb) }`);
                }
            });
            $("#dialog-count-bonus").val('');
        });
	},

    sounds : function(key) {
		var sound = new Audio("sound/"+key+".mp3");
		sound.volume = 0.3;
		sound.play();
	},
	
	format_number : function(n, c, d, t) {
		var c = isNaN(c = Math.abs(c)) ? 2 : c,
			d = d == undefined ? "." : d,
			t = t == undefined ? "," : t,
			s = n < 0 ? "-" : "",
			i = String(parseInt(n = Math.abs(Number(n) || 0).toFixed(c))),
			j = (j = i.length) > 3 ? j % 3 : 0;
	
		return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t);
	},
}
