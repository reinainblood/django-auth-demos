from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse

def login_view(request):
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)

        if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
            if user is not None:
                login(request, user)
                return JsonResponse({'success': True, 'redirect': '/admin/'})
            return JsonResponse({'success': False, 'error': 'Invalid credentials'})

        if user is not None:
            login(request, user)
            return redirect('/admin/')

    return render(request, 'auth_app/login.html')

